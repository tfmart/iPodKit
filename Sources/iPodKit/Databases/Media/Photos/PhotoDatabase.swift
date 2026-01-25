//
//  PhotoDatabase.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Photo Database parser for iPod Photo devices
/// 
/// The Photo Database stores manually added photos rather than album artwork.
/// Found in "/Photos/Photo Database" on iPod Photo devices.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Photo_Database
public struct PhotoDatabase: IPKParseable, Sendable {
    // Binary fields
    public let headerLength: UInt32
    public let versionNumber: UInt32
    public let numberOfChildren: UInt32
    
    // Photo albums and images
    public let albums: [PhotoAlbum]
    public let images: [PhotoImage]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhfd")
        
        // Parse header fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        _ = try Self.TotalLength().readUInt32(from: data)
        self.versionNumber = try Self.VersionNumber().readUInt32(from: data)
        self.numberOfChildren = try Self.NumberOfChildren().readUInt32(from: data)
        
        var albums: [PhotoAlbum] = []
        var images: [PhotoImage] = []
        var offset = Int(headerLength)
        
        // Parse children datasets
        for _ in 0..<numberOfChildren {
            guard offset + 12 <= data.count else { break }
            
            let childData = data.subdata(in: offset..<data.count)
            let childId = try childData.readString(at: 0, length: 4)
            
            switch childId {
            case "mhla": // Album list
                let albumList = try PhotoAlbumList(from: childData)
                albums = albumList.albums
                offset += Int(albumList.totalLength)
                
            case "mhli": // Image list
                let imageList = try PhotoImageList(from: childData)
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
public extension PhotoDatabase {
    /// Get JPEG images
    /// - Returns: Array of JPEG images
    func jpegImages() -> [PhotoImage] {
        return images.filter { $0.isJPEG }
    }
    
    /// Get PNG images
    /// - Returns: Array of PNG images
    func pngImages() -> [PhotoImage] {
        return images.filter { $0.isPNG }
    }
    
    /// Total photo storage size
    var totalPhotoSize: UInt64 {
        return images.reduce(0) { $0 + UInt64($1.imageSize) }
    }
    
    /// Formatted total photo size
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalPhotoSize))
    }
}

// MARK: - Field Definitions
extension PhotoDatabase {
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
