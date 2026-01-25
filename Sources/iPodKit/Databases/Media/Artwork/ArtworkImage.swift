//
//  ArtworkImage.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

public struct ArtworkImage: IPKParseable, Sendable {
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let imageId: UInt32
    public let correlationId: UInt32
    public let imageSize: UInt32
    public let imageHeight: UInt16
    public let imageWidth: UInt16
    public let verticalPadding: UInt16
    public let horizontalPadding: UInt16
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhii")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.imageId = try Self.ImageId().readUInt32(from: data)
        self.correlationId = try Self.CorrelationId().readUInt32(from: data)
        self.imageSize = try Self.ImageSize().readUInt32(from: data)
        self.imageHeight = try Self.ImageHeight().readUInt16(from: data)
        self.imageWidth = try Self.ImageWidth().readUInt16(from: data)
        self.verticalPadding = try Self.VerticalPadding().readUInt16(from: data)
        self.horizontalPadding = try Self.HorizontalPadding().readUInt16(from: data)
    }
}

public extension ArtworkImage {
    /// Image dimensions as a tuple
    var dimensions: (width: UInt16, height: UInt16) {
        return (imageWidth, imageHeight)
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

extension ArtworkImage {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct ImageId: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct CorrelationId: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct ImageSize: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    struct ImageHeight: IPKField {
        var offset: Int { 24 }
        var length: Int { 2 }
    }
    
    struct ImageWidth: IPKField {
        var offset: Int { 26 }
        var length: Int { 2 }
    }
    
    struct VerticalPadding: IPKField {
        var offset: Int { 28 }
        var length: Int { 2 }
    }
    
    struct HorizontalPadding: IPKField {
        var offset: Int { 30 }
        var length: Int { 2 }
    }
}
