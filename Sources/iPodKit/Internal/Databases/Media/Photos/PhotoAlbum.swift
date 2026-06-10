//
//  PhotoAlbum.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

internal struct PhotoAlbum: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfPhotos: UInt32
    let albumId: UInt32
    let nameLength: UInt32
    let name: String?
    let photoIds: [UInt32]
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhba")
        
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.numberOfPhotos = try Self.numberOfPhotosField.readUInt32(from: data)
        self.albumId = try Self.albumIdField.readUInt32(from: data)
        self.nameLength = try Self.nameLengthField.readUInt32(from: data)
        
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
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let numberOfPhotosField = IPKBinaryField(offset: 12, length: 4)
    static let albumIdField = IPKBinaryField(offset: 16, length: 4)
    static let nameLengthField = IPKBinaryField(offset: 20, length: 4)
}
