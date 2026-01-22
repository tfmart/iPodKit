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

// MARK: - Photo Album List
struct PhotoAlbumList: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfAlbums: UInt32
    let albums: [PhotoAlbum]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhla")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfAlbums = try Self.NumberOfAlbums().readUInt32(from: data)
        
        var albums: [PhotoAlbum] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfAlbums {
            guard offset < data.count else { break }
            
            let albumData = data.subdata(in: offset..<data.count)
            let album = try PhotoAlbum(from: albumData)
            albums.append(album)
            
            offset += Int(album.totalLength)
        }
        
        self.albums = albums
    }
}

// MARK: - Photo Album
public struct PhotoAlbum: IPKParseable, Sendable {
    let headerLength: UInt32
    public let totalLength: UInt32
    public let numberOfPhotos: UInt32
    public let albumId: UInt32
    public let nameLength: UInt32
    public let name: String?
    public let photoIds: [UInt32]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhba")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfPhotos = try Self.NumberOfPhotos().readUInt32(from: data)
        self.albumId = try Self.AlbumId().readUInt32(from: data)
        self.nameLength = try Self.NameLength().readUInt32(from: data)
        
        // Read album name if present
        var nameOffset = 24
        if nameLength > 0 {
            self.name = try? data.readMHODString(at: nameOffset, length: Int(nameLength))
            nameOffset += Int(nameLength)
        } else {
            self.name = nil
        }
        
        // Read photo IDs
        var photoIds: [UInt32] = []
        var offset = nameOffset
        
        for _ in 0..<numberOfPhotos {
            guard offset + 4 <= data.count else { break }
            let photoId = try data.readUInt32(at: offset)
            photoIds.append(photoId)
            offset += 4
        }
        
        self.photoIds = photoIds
    }
}

// MARK: - Photo Image List
struct PhotoImageList: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfImages: UInt32
    let images: [PhotoImage]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhli")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfImages = try Self.NumberOfImages().readUInt32(from: data)
        
        var images: [PhotoImage] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfImages {
            guard offset < data.count else { break }
            
            let imageData = data.subdata(in: offset..<data.count)
            let image = try PhotoImage(from: imageData)
            images.append(image)
            
            offset += Int(image.totalLength)
        }
        
        self.images = images
    }
}

// MARK: - Photo Image
public struct PhotoImage: IPKParseable, Sendable {
    let headerLength: UInt32
    public let totalLength: UInt32
    public let imageId: UInt32
    public let originalDate: UInt32
    public let imageSize: UInt32
    public let fileName: String?
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhii")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.imageId = try Self.ImageId().readUInt32(from: data)
        self.originalDate = try Self.OriginalDate().readUInt32(from: data)
        self.imageSize = try Self.ImageSize().readUInt32(from: data)
        
        // Try to read filename if there's more data
        if Int(headerLength) < data.count {
            let nameData = data.subdata(in: Int(headerLength)..<data.count)
            self.fileName = try? nameData.readMHODString(at: 0, length: nameData.count)
        } else {
            self.fileName = nil
        }
    }
}

// MARK: - Convenience Properties
public extension PhotoImage {
    /// File extension if available
    var fileExtension: String? {
        guard let fileName = fileName else { return nil }
        let url = URL(fileURLWithPath: fileName)
        let ext = url.pathExtension
        return ext.isEmpty ? nil : ext.lowercased()
    }
    
    /// Check if this is a JPEG image
    var isJPEG: Bool {
        return fileExtension == "jpg" || fileExtension == "jpeg"
    }
    
    /// Check if this is a PNG image
    var isPNG: Bool {
        return fileExtension == "png"
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

extension PhotoAlbumList {
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

extension PhotoAlbum {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfPhotos: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct AlbumId: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct NameLength: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
}

extension PhotoImageList {
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

extension PhotoImage {
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
    
    struct OriginalDate: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct ImageSize: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
}