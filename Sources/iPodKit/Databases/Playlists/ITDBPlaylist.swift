
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
struct ITDBPlaylist: IPKParseable {
    let id: String = "mhyp"

    let headerLength: UInt32
    let totalLength: UInt32
    let dataObjectChildCount: UInt32
    let playlistItemCount: UInt32
    let isMasterPlaylist: Bool
    let isPodcast: Bool
    let timestamp: UInt32
    let persistentPlaylistId: UInt64

    /// Playlist name parsed from child mhod objects
    let name: String?

    /// Track unique IDs in this playlist, parsed from mhip children
    let trackIds: [UInt32]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhyp")

        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.dataObjectChildCount = try Self.DataObjectChildCount().readUInt32(from: data)
        self.playlistItemCount = try Self.PlaylistItemCount().readUInt32(from: data)
        self.isMasterPlaylist = try Self.IsMasterPlaylistFlag().readUInt8(from: data) == 1
        self.isPodcast = try Self.PodcastFlag().readUInt16(from: data) == 1
        self.timestamp = try Self.Timestamp().readUInt32(from: data)
        self.persistentPlaylistId = try Self.PersistentPlaylistId().readUInt64(from: data)

        // Parse child objects (mhod for name, mhip for track items)
        var parsedName: String? = nil
        var parsedTrackIds: [UInt32] = []
        var offset = Int(headerLength)

        // First parse mhod objects (data objects containing name, etc.)
        for _ in 0..<dataObjectChildCount {
            guard offset + 12 < data.count else { break }

            let childData = data.subdata(in: offset..<data.count)

            // Check if this is an mhod
            if childData.count >= 4,
               String(data: childData.subdata(in: 0..<4), encoding: .ascii) == "mhod" {
                let mhod = try ITDBDataObject(from: childData)

                // Type 1 is the playlist name
                if mhod.type == .title, let stringValue = mhod.stringValue {
                    parsedName = stringValue
                }

                offset += Int(mhod.totalLength)
            } else {
                break
            }
        }

        // Then parse mhip objects (playlist items containing track references)
        for _ in 0..<playlistItemCount {
            guard offset + 28 < data.count else { break }

            let childData = data.subdata(in: offset..<data.count)

            // Check if this is an mhip
            if childData.count >= 4,
               String(data: childData.subdata(in: 0..<4), encoding: .ascii) == "mhip" {
                // Parse mhip to get track ID
                let itemTotalLength = try ITDBPlaylistItem.TotalLength().readUInt32(from: childData)
                let trackId = try ITDBPlaylistItem.TrackId().readUInt32(from: childData)
                parsedTrackIds.append(trackId)

                offset += Int(itemTotalLength)
            } else {
                break
            }
        }

        self.name = parsedName
        self.trackIds = parsedTrackIds
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
