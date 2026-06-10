//
//  ITDBTrackList.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// TrackList object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#TrackList
internal struct ITDBTrackList: IPKParseable, Sendable {
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhlt")
        _ = try Self.headerLengthField.readUInt32(from: data)
        _ = try Self.numberOfSongsField.readUInt32(from: data)
    }
    
    func getNumberOfSongs(from data: Data) throws -> UInt32 {
        return try Self.numberOfSongsField.readUInt32(from: data)
    }
}

extension ITDBTrackList {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let numberOfSongsField = IPKBinaryField(offset: 8, length: 4)
}
