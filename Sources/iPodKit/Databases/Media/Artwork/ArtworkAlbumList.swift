//
//  ArtworkAlbumList.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

struct ArtworkAlbumList: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfAlbums: UInt32
    let albums: [ArtworkAlbum]

    init(from data: Data) throws {
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
