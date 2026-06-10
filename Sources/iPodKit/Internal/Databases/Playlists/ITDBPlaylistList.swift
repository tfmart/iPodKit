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
        _ = try Self.headerLengthField.readUInt32(from: data)
        _ = try Self.numberOfPlaylistsField.readUInt32(from: data)
    }
    
    func getNumberOfPlaylists(from data: Data) throws -> UInt32 {
        return try Self.numberOfPlaylistsField.readUInt32(from: data)
    }
}

extension ITDBPlaylistList {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let numberOfPlaylistsField = IPKBinaryField(offset: 8, length: 4)
}
