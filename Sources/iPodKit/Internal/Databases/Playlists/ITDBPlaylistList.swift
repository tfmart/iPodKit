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
internal struct ITDBPlaylistList: IPKParseable, Sendable {
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhlp")
        _ = try Self.HeaderLength().readUInt32(from: data)
        _ = try Self.NumberOfPlaylists().readUInt32(from: data)
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
