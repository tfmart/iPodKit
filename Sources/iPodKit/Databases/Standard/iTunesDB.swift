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
public struct iTunesDB: IPKParseable {
    let id: String = "mhbd"
    
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let versionNumber: UInt32
    public let numberOfChildren: UInt32
    public let databaseId: UInt64
    public let languageId: UInt16
    public let libraryPersistentId: UInt64
    public let hash: Data
    public let timezoneOffset: UInt32
    public let obscureHash: Data
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhbd")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.versionNumber = try Self.VersionNumber().readUInt32(from: data)
        self.numberOfChildren = try Self.NumberOfChildren().readUInt32(from: data)
        self.databaseId = try Self.DatabaseId().readUInt64(from: data)
        self.languageId = try Self.LanguageId().readUInt16(from: data)
        self.libraryPersistentId = try Self.LibraryPersistentId().readUInt64(from: data)
        self.hash = try Self.Hash().readBytes(from: data)
        self.timezoneOffset = try Self.TimezoneOffset().readUInt32(from: data)
        
        // ObscureHash only exists in newer versions (dbversion >= 0x19)
        if headerLength >= 108 && data.count >= 108 {
            self.obscureHash = try Self.ObscureHash().readBytes(from: data)
        } else {
            self.obscureHash = Data()
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
    
    struct Unknown1: IPKField {
        var offset: Int { 12 }
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
    
    struct Unknown2: IPKField {
        var offset: Int { 32 }
        var length: Int { 2 }
    }
    
    struct Unknown3: IPKField {
        var offset: Int { 34 }
        var length: Int { 2 }
    }
    
    struct Unknown4: IPKField {
        var offset: Int { 36 }
        var length: Int { 4 }
    }
    
    struct Unknown5: IPKField {
        var offset: Int { 40 }
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
    
    struct Unknown6: IPKField {
        var offset: Int { 58 }
        var length: Int { 4 }
    }
    
    struct Unknown7: IPKField {
        var offset: Int { 62 }
        var length: Int { 2 }
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
