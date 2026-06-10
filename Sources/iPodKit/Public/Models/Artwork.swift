//
//  Artwork.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation
import CoreGraphics

/// Artwork associated with a track.
///
/// ## Overview
///
/// Access artwork through ``Track/artwork``. Use ``sizes`` to inspect the
/// thumbnail sizes stored for the track.
///
/// ```swift
/// if let artwork = track.artwork {
///     print(artwork.sizes)
/// }
/// ```
///
/// Call ``image(size:)`` with no arguments to load the largest available image:
///
/// ```swift
/// if let artwork = track.artwork {
///     let image = try await artwork.image()
///     print("Artwork size: \(image.width)x\(image.height)")
/// }
/// ```
///
/// Request a specific thumbnail by passing one of the available sizes:
///
/// ```swift
/// if let artwork = track.artwork,
///    let size = artwork.sizes.first {
///     let image = try await artwork.image(size: size)
/// }
/// ```
///
/// ## Topics
///
/// ### Available Sizes
/// - ``Size``
/// - ``sizes``
///
/// ### Loading Images
/// - ``image(size:)``
public struct Artwork: Sendable {

    /// Available thumbnail sizes in pixels.
    ///
    /// iPods typically store artwork at multiple resolutions (e.g., 56x56,
    /// 140x140). Check this array to see what sizes are available before
    /// requesting a specific size with ``image(size:)``.
    public let sizes: [Size]

    private let iPodURL: URL
    private let thumbnails: [ArtworkThumbnail]

    internal init(from imageItem: ArtworkImageItem, iPodURL: URL) {
        self.sizes = imageItem.thumbnails.map { Size(width: Int($0.imageWidth), height: Int($0.imageHeight)) }
        self.iPodURL = iPodURL
        self.thumbnails = imageItem.thumbnails
    }

    /// Loads an artwork image.
    ///
    /// When `size` is `nil`, this method returns the largest available image.
    ///
    /// - Parameter size: Desired thumbnail size in pixels, or `nil` for the largest available image.
    /// - Returns: A `CGImage` decoded from the iPod's artwork database.
    /// - Throws: ``iPodError/artworkNotFound`` if no thumbnail matches the requested size.
    /// - Throws: ``iPodError/artworkDecodingFailed`` if the image data cannot be decoded.
    public func image(size: Size? = nil) async throws(iPodError) -> CGImage {
        try Self.checkCancellation()

        let thumbnail = try thumbnail(for: size)
        let iPodURL = iPodURL
        // Untyped throws: a typed-throws closure here crashes the Swift 6 compiler during IR generation.
        let task = Task.detached(priority: Task.currentPriority) { () throws -> CGImage in
            try Self.checkCancellation()
            let image = try ArtworkDecoder.image(from: thumbnail, iPodURL: iPodURL)
            try Self.checkCancellation()
            return image
        }

        do {
            return try await withTaskCancellationHandler(
                operation: {
                    try await task.value
                },
                onCancel: {
                    task.cancel()
                }
            )
        } catch let error as iPodError {
            throw error
        } catch {
            throw iPodError.cancelled
        }
    }
}

private extension Artwork {

    static func checkCancellation() throws(iPodError) {
        if Task.isCancelled {
            throw iPodError.cancelled
        }
    }

    func thumbnail(for size: Size?) throws(iPodError) -> ArtworkThumbnail {
        let thumbnail: ArtworkThumbnail?
        if let size {
            thumbnail = thumbnails.first { thumbnail in
                Int(thumbnail.imageWidth) == size.width && Int(thumbnail.imageHeight) == size.height
            }
        } else {
            thumbnail = thumbnails.max { $0.pixelCount < $1.pixelCount }
        }

        guard let thumbnail else {
            throw iPodError.artworkNotFound
        }
        return thumbnail
    }
}
