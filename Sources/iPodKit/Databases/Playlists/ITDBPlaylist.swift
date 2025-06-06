//
//  ITDBPlaylist.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Playlist object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Playlist
public struct ITDBPlaylist: IPKParseable {
    let id: String = "mhyp"
    
    let headerLength: UInt32
    let totalLength: UInt32
    let dataObjectChildCount: UInt32
    let playlistItemCount: UInt32
    let isMasterPlaylist: Bool
    let timestamp: UInt32
    let persistentPlaylistId: UInt64
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhyp")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.dataObjectChildCount = try Self.DataObjectChildCount().readUInt32(from: data)
        self.playlistItemCount = try Self.PlaylistItemCount().readUInt32(from: data)
        self.isMasterPlaylist = try Self.IsMasterPlaylistFlag().readUInt8(from: data) == 1
        self.timestamp = try Self.Timestamp().readUInt32(from: data)
        self.persistentPlaylistId = try Self.PersistentPlaylistId().readUInt64(from: data)
    }
    
    func getTotalLength(from data: Data) throws -> UInt32 {
        return try Self.TotalLength().readUInt32(from: data)
    }
}

extension ITDBPlaylist {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct DataObjectChildCount: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct PlaylistItemCount: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct IsMasterPlaylistFlag: IPKField {
        var offset: Int { 20 }
        var length: Int { 1 }
    }
    
    struct Unknown: IPKField {
        var offset: Int { 21 }
        var length: Int { 3 }
    }
    
    struct Timestamp: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
    
    struct PersistentPlaylistId: IPKField {
        var offset: Int { 28 }
        var length: Int { 8 }
    }
    
    struct Unknown3: IPKField {
        var offset: Int { 36 }
        var length: Int { 4 }
    }
    
    struct StringMHODCount: IPKField {
        var offset: Int { 40 }
        var length: Int { 2 }
    }
    
    struct PodcastFlag: IPKField {
        var offset: Int { 42 }
        var length: Int { 2 }
    }
    
    struct ListSortOrder: IPKField {
        var offset: Int { 44 }
        var length: Int { 4 }
    }
}