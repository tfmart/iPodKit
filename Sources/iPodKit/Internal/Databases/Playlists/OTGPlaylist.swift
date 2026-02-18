//
//  OTGPlaylist.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// On-The-Go Playlist File parser for iPod database
/// 
/// The OTG Playlist file contains user-created playlists made directly
/// on the iPod using track indexes. It becomes invalid when iTunesDB changes.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#OTG_Playlist_File
struct OTGPlaylist: IPKParseable, Sendable {
    // Binary fields
    public let headerLength: UInt32
    public let numberOfSongs: UInt32
    
    // Track index entries
    public let trackIndexes: [UInt32]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhpo")
        
        // Parse header fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        _ = try Self.EntryLength().readUInt32(from: data)
        self.numberOfSongs = try Self.NumberOfSongs().readUInt32(from: data)
        
        // Parse track indexes
        var indexes: [UInt32] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfSongs {
            guard offset + 4 <= data.count else { break }
            
            let trackIndex = try data.readUInt32(at: offset)
            indexes.append(trackIndex)
            offset += 4
        }
        
        self.trackIndexes = indexes
    }
}

// MARK: - Public API
extension OTGPlaylist {
    /// Check if the playlist is empty
    var isEmpty: Bool {
        return trackIndexes.isEmpty
    }

    /// Get the number of tracks in the playlist
    var count: Int {
        return trackIndexes.count
    }
}

// MARK: - Field Definitions
extension OTGPlaylist {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct EntryLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfSongs: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}