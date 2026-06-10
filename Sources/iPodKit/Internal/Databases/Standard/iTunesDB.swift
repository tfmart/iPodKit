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
    let headerLength: UInt32
    let totalLength: UInt32
    let versionNumber: UInt32
    let numberOfChildren: UInt32

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhbd")

        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.versionNumber = try Self.versionNumberField.readUInt32(from: data)
        self.numberOfChildren = try Self.numberOfChildrenField.readUInt32(from: data)
        _ = try Self.databaseIdField.readUInt64(from: data)
        _ = try Self.languageIdField.readUInt16(from: data)
        _ = try Self.libraryPersistentIdField.readUInt64(from: data)
        _ = try Self.hashField.readBytes(from: data)
        _ = try Self.timezoneOffsetField.readUInt32(from: data)

        // ObscureHash only exists in newer versions (dbversion >= 0x19)
        if headerLength >= 108 && data.count >= 108 {
            _ = try Self.obscureHashField.readBytes(from: data)
        }
    }
}

extension iTunesDB {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let versionNumberField = IPKBinaryField(offset: 16, length: 4)
    static let numberOfChildrenField = IPKBinaryField(offset: 20, length: 4)
    static let databaseIdField = IPKBinaryField(offset: 24, length: 8)
    static let languageIdField = IPKBinaryField(offset: 48, length: 2)
    static let libraryPersistentIdField = IPKBinaryField(offset: 50, length: 8)
    static let hashField = IPKBinaryField(offset: 64, length: 20)
    static let timezoneOffsetField = IPKBinaryField(offset: 84, length: 4)
    static let obscureHashField = IPKBinaryField(offset: 88, length: 20)
}
