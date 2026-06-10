
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
internal struct ITDBPlaylist: IPKParseable, Sendable {
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

        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.dataObjectChildCount = try Self.dataObjectChildCountField.readUInt32(from: data)
        self.playlistItemCount = try Self.playlistItemCountField.readUInt32(from: data)
        self.isMasterPlaylist = try Self.isMasterPlaylistFlagField.readUInt8(from: data) == 1
        self.isPodcast = try Self.podcastFlagField.readUInt16(from: data) == 1
        self.timestamp = try Self.timestampField.readUInt32(from: data)
        self.persistentPlaylistId = try Self.persistentPlaylistIdField.readUInt64(from: data)

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
                let itemTotalLength = try ITDBPlaylistItem.totalLengthField.readUInt32(from: childData)
                let trackId = try ITDBPlaylistItem.trackIdField.readUInt32(from: childData)
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
        return try Self.totalLengthField.readUInt32(from: data)
    }
}

extension ITDBPlaylist {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let dataObjectChildCountField = IPKBinaryField(offset: 12, length: 4)
    static let playlistItemCountField = IPKBinaryField(offset: 16, length: 4)
    static let isMasterPlaylistFlagField = IPKBinaryField(offset: 20, length: 1)
    static let timestampField = IPKBinaryField(offset: 24, length: 4)
    static let persistentPlaylistIdField = IPKBinaryField(offset: 28, length: 8)
    static let podcastFlagField = IPKBinaryField(offset: 42, length: 2)
}
