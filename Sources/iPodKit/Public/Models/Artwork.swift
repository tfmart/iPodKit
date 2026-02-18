//
//  Artwork.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation
import CoreGraphics

/// Artwork associated with a track.
public struct Artwork: Sendable {

    /// Available thumbnail sizes (width, height) in pixels
    public let sizes: [(width: Int, height: Int)]

    private let iPodURL: URL
    private let thumbnails: [ArtworkThumbnail]

    internal init(from imageItem: ArtworkImageItem, iPodURL: URL) {
        self.sizes = imageItem.thumbnails.map { (Int($0.imageWidth), Int($0.imageHeight)) }
        self.iPodURL = iPodURL
        self.thumbnails = imageItem.thumbnails
    }

    /// Load artwork as CGImage (largest available size)
    public func loadImage() throws -> CGImage {
        guard let thumbnail = thumbnails.max(by: { $0.pixelCount < $1.pixelCount }) else {
            throw IPKError.artworkNotFound
        }
        return try ArtworkDecoder.loadImage(from: thumbnail, iPodURL: iPodURL)
    }

    /// Load artwork as CGImage for a specific size
    public func loadImage(width: Int, height: Int) throws -> CGImage {
        guard let thumbnail = thumbnails.first(where: {
            Int($0.imageWidth) == width && Int($0.imageHeight) == height
        }) else {
            throw IPKError.artworkNotFound
        }
        return try ArtworkDecoder.loadImage(from: thumbnail, iPodURL: iPodURL)
    }
}
