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
public struct ArtworkDatabase: IPKParseable, Sendable {
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

// MARK: - Public API
public extension ArtworkDatabase {
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
