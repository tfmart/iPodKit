//
//  Artwork.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation
import CoreGraphics

/// Album artwork associated with a track.
///
/// iPods store artwork in a dedicated database with multiple thumbnail sizes.
/// Call ``loadImage(width:height:)`` with no arguments to get the largest
/// available size, or pass specific dimensions to request a particular resolution.
///
/// ```swift
/// if let artwork = track.artwork {
///     let largest = try artwork.loadImage()
///     let small   = try artwork.loadImage(width: 56, height: 56)
/// }
/// ```
///
/// > Note: Artwork loading reads from the iPod's filesystem. The iPod must
/// > still be mounted at its original path for image loading to succeed.
///
/// ## Topics
///
/// ### Available Sizes
/// - ``sizes``
///
/// ### Loading Images
/// - ``loadImage(width:height:)``
public struct Artwork: Sendable {

    /// Available thumbnail sizes as (width, height) pairs in pixels.
    ///
    /// iPods typically store artwork at multiple resolutions (e.g., 56x56,
    /// 140x140). Check this array to see what sizes are available before
    /// requesting a specific size with ``loadImage(width:height:)``.
    public let sizes: [(width: Int, height: Int)]

    private let iPodURL: URL
    private let thumbnails: [ArtworkThumbnail]

    internal init(from imageItem: ArtworkImageItem, iPodURL: URL) {
        self.sizes = imageItem.thumbnails.map { (Int($0.imageWidth), Int($0.imageHeight)) }
        self.iPodURL = iPodURL
        self.thumbnails = imageItem.thumbnails
    }

    /// Load the artwork image.
    ///
    /// When called without arguments, returns the largest available resolution.
    /// Pass specific dimensions to request a particular thumbnail size — use
    /// ``sizes`` to discover what's available.
    ///
    /// - Parameters:
    ///   - width: Desired image width in pixels, or `nil` for the largest available.
    ///   - height: Desired image height in pixels, or `nil` for the largest available.
    /// - Returns: A `CGImage` decoded from the iPod's artwork database.
    /// - Throws: ``IPKError/artworkNotFound`` if no thumbnail matches the requested size.
    /// - Throws: ``IPKError/artworkDecodingFailed`` if the image data cannot be decoded.
    public func loadImage(width: Int? = nil, height: Int? = nil) throws -> CGImage {
        let thumbnail: ArtworkThumbnail?
        if let width, let height {
            thumbnail = thumbnails.first(where: {
                Int($0.imageWidth) == width && Int($0.imageHeight) == height
            })
        } else {
            thumbnail = thumbnails.max(by: { $0.pixelCount < $1.pixelCount })
        }

        guard let thumbnail else {
            throw IPKError.artworkNotFound
        }
        return try ArtworkDecoder.loadImage(from: thumbnail, iPodURL: iPodURL)
    }
}
