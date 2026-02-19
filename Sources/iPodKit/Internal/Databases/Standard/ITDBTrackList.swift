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
        _ = try Self.HeaderLength().readUInt32(from: data)
        _ = try Self.NumberOfSongs().readUInt32(from: data)
    }
    
    func getNumberOfSongs(from data: Data) throws -> UInt32 {
        return try Self.NumberOfSongs().readUInt32(from: data)
    }
}

extension ITDBTrackList {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct NumberOfSongs: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
}
