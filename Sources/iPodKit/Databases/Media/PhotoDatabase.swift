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
public struct PhotoDatabase: IPKParseable {
    let id: String = "mhfd"
    
    // Binary fields
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let versionNumber: UInt32
    public let numberOfChildren: UInt32
    
    // Photo albums and images
    public let albums: [PhotoAlbum]
    public let images: [PhotoImage]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhfd")
        
        // Parse header fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
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
public struct PhotoAlbumList: IPKParseable {
    let id: String = "mhla"
    
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let numberOfAlbums: UInt32
    public let albums: [PhotoAlbum]
    
    public init(from data: Data) throws {
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
public struct PhotoAlbum: IPKParseable {
    let id: String = "mhba"
    
    public let headerLength: UInt32
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
public struct PhotoImageList: IPKParseable {
    let id: String = "mhli"
    
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let numberOfImages: UInt32
    public let images: [PhotoImage]
    
    public init(from data: Data) throws {
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
public struct PhotoImage: IPKParseable {
    let id: String = "mhii"
    
    public let headerLength: UInt32
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
public extension PhotoAlbum {
    /// Display name for the album
    var displayName: String {
        return name ?? "Unnamed Album"
    }
    
    /// Number of photos in the album
    var photoCount: Int {
        return photoIds.count
    }
    
    /// Check if album is empty
    var isEmpty: Bool {
        return photoIds.isEmpty
    }
}

public extension PhotoImage {
    /// Original date converted from Mac epoch timestamp
    var originalDateConverted: Date? {
        guard originalDate > 0 else { return nil }
        let macEpochOffset: TimeInterval = 2082844800
        let unixTimestamp = TimeInterval(originalDate) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }
    
    /// Formatted original date string
    var originalDateFormatted: String {
        guard let date = originalDateConverted else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Formatted image size
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(imageSize))
    }
    
    /// Display name for the image
    var displayName: String {
        return fileName ?? "IMG_\(imageId)"
    }
    
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
    /// Get image by ID
    /// - Parameter imageId: Image ID to search for
    /// - Returns: Photo image if found
    func image(withId imageId: UInt32) -> PhotoImage? {
        return images.first { $0.imageId == imageId }
    }
    
    /// Get album by ID
    /// - Parameter albumId: Album ID to search for
    /// - Returns: Photo album if found
    func album(withId albumId: UInt32) -> PhotoAlbum? {
        return albums.first { $0.albumId == albumId }
    }
    
    /// Get album by name
    /// - Parameter name: Album name to search for
    /// - Returns: Photo album if found
    func album(withName name: String) -> PhotoAlbum? {
        return albums.first { album in
            album.name?.localizedCaseInsensitiveContains(name) == true
        }
    }
    
    /// Get images in a specific album
    /// - Parameter album: Photo album
    /// - Returns: Array of images in the album
    func images(inAlbum album: PhotoAlbum) -> [PhotoImage] {
        return album.photoIds.compactMap { photoId in
            image(withId: photoId)
        }
    }
    
    /// Get all album names
    /// - Returns: Array of album names
    func allAlbumNames() -> [String] {
        return albums.compactMap { $0.name }
    }
    
    /// Get images by file extension
    /// - Parameter extension: File extension to filter by
    /// - Returns: Array of matching images
    func images(withExtension extension: String) -> [PhotoImage] {
        return images.filter { $0.fileExtension == `extension`.lowercased() }
    }
    
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
    
    /// Get images taken after a specific date
    /// - Parameter date: Date to filter from
    /// - Returns: Array of recent images
    func images(takenAfter date: Date) -> [PhotoImage] {
        return images.filter { image in
            guard let originalDate = image.originalDateConverted else { return false }
            return originalDate > date
        }
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