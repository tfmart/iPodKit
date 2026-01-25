//
//  ArtworkImage.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

/// Legacy artwork image structure for backwards compatibility.
///
/// This is a flattened representation combining data from mhii and mhni.
/// For new code, prefer using `ArtworkImageItem` and `ArtworkThumbnail`.
public struct ArtworkImage: Sendable {
    public let correlationId: UInt32
    public let ithmbOffset: UInt32
    public let imageSize: UInt32
    public let imageHeight: UInt16
    public let imageWidth: UInt16
    public let verticalPadding: Int16
    public let horizontalPadding: Int16
    public let songId: UInt64

    public init(
        correlationId: UInt32,
        ithmbOffset: UInt32,
        imageSize: UInt32,
        imageHeight: UInt16,
        imageWidth: UInt16,
        verticalPadding: Int16,
        horizontalPadding: Int16,
        songId: UInt64
    ) {
        self.correlationId = correlationId
        self.ithmbOffset = ithmbOffset
        self.imageSize = imageSize
        self.imageHeight = imageHeight
        self.imageWidth = imageWidth
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.songId = songId
    }
}

// MARK: - Convenience Properties
public extension ArtworkImage {
    /// Image dimensions as a tuple
    var dimensions: (width: UInt16, height: UInt16) {
        (imageWidth, imageHeight)
    }

    /// The .ithmb filename derived from correlation ID
    var ithmbFilename: String {
        "F\(correlationId)_1.ithmb"
    }

    /// Formatted image size
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(imageSize))
    }

    /// Image aspect ratio
    var aspectRatio: Double {
        guard imageHeight > 0 else { return 0 }
        return Double(imageWidth) / Double(imageHeight)
    }
}
