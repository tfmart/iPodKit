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
struct ITDBTrackList: IPKParseable {
    let id: String = "mhlt"
    
    let headerLength: UInt32
    let numberOfSongs: UInt32
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhlt")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.numberOfSongs = try Self.NumberOfSongs().readUInt32(from: data)
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
