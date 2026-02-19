//
//  iTunesDB.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

/// This is the primary database for the iPod. It contains all information about the songs that the iPod is capable of playing, as well as the playlists. It's never written to by the Apple iPod firmware. During an autosync, iTunes completely overwrites this file.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Database_Object
internal struct iTunesDB: IPKParseable, Sendable {
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let versionNumber: UInt32
    public let numberOfChildren: UInt32

    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhbd")

        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.versionNumber = try Self.VersionNumber().readUInt32(from: data)
        self.numberOfChildren = try Self.NumberOfChildren().readUInt32(from: data)
        _ = try Self.DatabaseId().readUInt64(from: data)
        _ = try Self.LanguageId().readUInt16(from: data)
        _ = try Self.LibraryPersistentId().readUInt64(from: data)
        _ = try Self.Hash().readBytes(from: data)
        _ = try Self.TimezoneOffset().readUInt32(from: data)

        // ObscureHash only exists in newer versions (dbversion >= 0x19)
        if headerLength >= 108 && data.count >= 108 {
            _ = try Self.ObscureHash().readBytes(from: data)
        }
    }
    
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct VersionNumber: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct NumberOfChildren: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    struct DatabaseId: IPKField {
        var offset: Int { 24 }
        var length: Int { 8 }
    }
    
    struct LanguageId: IPKField {
        var offset: Int { 48 }
        var length: Int { 2 }
    }
    
    struct LibraryPersistentId: IPKField {
        var offset: Int { 50 }
        var length: Int { 8 }
    }
    
    struct Hash: IPKField {
        var offset: Int { 64 }
        var length: Int { 20 }
    }
    
    struct TimezoneOffset: IPKField {
        var offset: Int { 84 }
        var length: Int { 4 }
    }
    
    struct ObscureHash: IPKField {
        var offset: Int { 88 }
        var length: Int { 20 }
    }
}
