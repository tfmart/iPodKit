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
internal struct PhotoDatabase: IPKParseable, Sendable {
    // Binary fields
    let headerLength: UInt32
    let versionNumber: UInt32
    let numberOfChildren: UInt32
    
    // Photo albums and images
    let albums: [PhotoAlbum]
    let images: [PhotoImage]
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhfd")
        
        // Parse header fields
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        _ = try Self.totalLengthField.readUInt32(from: data)
        self.versionNumber = try Self.versionNumberField.readUInt32(from: data)
        self.numberOfChildren = try Self.numberOfChildrenField.readUInt32(from: data)
        
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

// MARK: - Internal API
extension PhotoDatabase {
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
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let versionNumberField = IPKBinaryField(offset: 12, length: 4)
    static let numberOfChildrenField = IPKBinaryField(offset: 16, length: 4)
}
