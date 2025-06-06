//
//  ITDBPlaylistList.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Playlist List object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Playlist_List
struct ITDBPlaylistList: IPKParseable {
    let id: String = "mhlp"
    
    let headerLength: UInt32
    let numberOfPlaylists: UInt32
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhlp")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.numberOfPlaylists = try Self.NumberOfPlaylists().readUInt32(from: data)
    }
    
    func getNumberOfPlaylists(from data: Data) throws -> UInt32 {
        return try Self.NumberOfPlaylists().readUInt32(from: data)
    }
}

extension ITDBPlaylistList {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct NumberOfPlaylists: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
}
