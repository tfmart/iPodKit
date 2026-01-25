//
//  PhotoAlbum.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

struct PhotoAlbum: IPKParseable, Sendable {
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
