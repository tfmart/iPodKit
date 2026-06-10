//
//  PhotoAlbumList.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

internal struct PhotoAlbumList: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfAlbums: UInt32
    let albums: [PhotoAlbum]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhla")
        
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.numberOfAlbums = try Self.numberOfAlbumsField.readUInt32(from: data)
        
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

extension PhotoAlbumList {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let numberOfAlbumsField = IPKBinaryField(offset: 12, length: 4)
}
