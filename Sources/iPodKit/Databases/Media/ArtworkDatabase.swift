//
//  ArtworkDatabase.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Artwork Database parser for iPod Photo devices
/// 
/// The Artwork Database stores album artwork data for iPod Photo devices.
/// Artwork files are stored separately in the iPod_Control\Artwork folder.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Artwork_Database
public struct ArtworkDatabase: IPKParseable {
    let id: String = "mhfd"
    
    // Binary fields
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let versionNumber: UInt32
    public let numberOfChildren: UInt32
    
    // Artwork albums and images
    public let albums: [ArtworkAlbum]
    public let images: [ArtworkImage]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhfd")
        
        // Parse header fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.versionNumber = try Self.VersionNumber().readUInt32(from: data)
        self.numberOfChildren = try Self.NumberOfChildren().readUInt32(from: data)
        
        var albums: [ArtworkAlbum] = []
        var images: [ArtworkImage] = []
        var offset = Int(headerLength)
        
        // Parse children datasets
        for _ in 0..<numberOfChildren {
            guard offset + 12 <= data.count else { break }
            
            let childData = data.subdata(in: offset..<data.count)
            let childId = try childData.readString(at: 0, length: 4)
            
            switch childId {
            case "mhla": // Album list
                let albumList = try ArtworkAlbumList(from: childData)
                albums = albumList.albums
                offset += Int(albumList.totalLength)
                
            case "mhli": // Image list
                let imageList = try ArtworkImageList(from: childData)
                images = imageList.images
                offset += Int(imageList.totalLength)
                
            default:
                // Skip unknown sections
                let sectionLength = try childData.readUInt32(at: 8)
                offset += Int(sectionLength)
            }
        }
        
        self.albums = albums
        self.images = images
    }
}

// MARK: - Artwork Album List
public struct ArtworkAlbumList: IPKParseable {
    let id: String = "mhla"
    
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let numberOfAlbums: UInt32
    public let albums: [ArtworkAlbum]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhla")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfAlbums = try Self.NumberOfAlbums().readUInt32(from: data)
        
        var albums: [ArtworkAlbum] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfAlbums {
            guard offset < data.count else { break }
            
            let albumData = data.subdata(in: offset..<data.count)
            let album = try ArtworkAlbum(from: albumData)
            albums.append(album)
            
            offset += Int(album.totalLength)
        }
        
        self.albums = albums
    }
}

// MARK: - Artwork Album
public struct ArtworkAlbum: IPKParseable {
    let id: String = "mhod"
    
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let artworkId: UInt32
    public let unknownValue: UInt32
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhod")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.artworkId = try Self.ArtworkId().readUInt32(from: data)
        self.unknownValue = try Self.UnknownValue().readUInt32(from: data)
    }
}

// MARK: - Artwork Image List
public struct ArtworkImageList: IPKParseable {
    let id: String = "mhli"
    
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let numberOfImages: UInt32
    public let images: [ArtworkImage]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhli")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfImages = try Self.NumberOfImages().readUInt32(from: data)
        
        var images: [ArtworkImage] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfImages {
            guard offset < data.count else { break }
            
            let imageData = data.subdata(in: offset..<data.count)
            let image = try ArtworkImage(from: imageData)
            images.append(image)
            
            offset += Int(image.totalLength)
        }
        
        self.images = images
    }
}

// MARK: - Artwork Image
public struct ArtworkImage: IPKParseable {
    let id: String = "mhii"
    
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

// MARK: - Convenience Properties
public extension ArtworkImage {
    /// Image dimensions as a tuple
    var dimensions: (width: UInt16, height: UInt16) {
        return (imageWidth, imageHeight)
    }
    
    /// Image padding as a tuple
    var padding: (horizontal: UInt16, vertical: UInt16) {
        return (horizontalPadding, verticalPadding)
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

// MARK: - Public API
public extension ArtworkDatabase {
    /// Get image by ID
    /// - Parameter imageId: Image ID to search for
    /// - Returns: Artwork image if found
    func image(withId imageId: UInt32) -> ArtworkImage? {
        return images.first { $0.imageId == imageId }
    }
    
    /// Get album by artwork ID
    /// - Parameter artworkId: Artwork ID to search for
    /// - Returns: Artwork album if found
    func album(withArtworkId artworkId: UInt32) -> ArtworkAlbum? {
        return albums.first { $0.artworkId == artworkId }
    }
    
    /// Get all unique image dimensions
    /// - Returns: Array of unique dimension tuples
    func uniqueImageDimensions() -> [(width: UInt16, height: UInt16)] {
        let dimensions = images.map { $0.dimensions }
        return Array(Set(dimensions.map { "\($0.width)x\($0.height)" }))
            .compactMap { dimensionString in
                let parts = dimensionString.split(separator: "x")
                guard parts.count == 2,
                      let width = UInt16(parts[0]),
                      let height = UInt16(parts[1]) else { return nil }
                return (width, height)
            }
    }
    
    /// Get images by correlation ID
    /// - Parameter correlationId: Correlation ID to filter by
    /// - Returns: Array of matching images
    func images(withCorrelationId correlationId: UInt32) -> [ArtworkImage] {
        return images.filter { $0.correlationId == correlationId }
    }
    
    /// Total artwork storage size
    var totalArtworkSize: UInt64 {
        return images.reduce(0) { $0 + UInt64($1.imageSize) }
    }
    
    /// Formatted total artwork size
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalArtworkSize))
    }
}

// MARK: - Field Definitions
extension ArtworkDatabase {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct VersionNumber: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct NumberOfChildren: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
}

extension ArtworkAlbumList {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfAlbums: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}

extension ArtworkAlbum {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct ArtworkId: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct UnknownValue: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
}

extension ArtworkImageList {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfImages: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
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