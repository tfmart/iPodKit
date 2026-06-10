//
//  iTunesSDTrack.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

internal struct iTunesSDTrack: IPKParseable, Sendable {
    // Binary fields (all big-endian)
    let length: UInt32
    let startTime: UInt32
    let stopTime: UInt32
    let volume: UInt32
    let shuffleFlag: UInt32
    let bookmarkFlag: UInt32
    let filename: String
    
    init(from data: Data) throws {
        guard data.count >= 512 else {
            throw IPKParsingError.insufficientData
        }
        
        // Read binary fields (big-endian)
        self.length = try Self.lengthField.readUInt32BigEndian(from: data)
        _ = try Self.fileTypeField.readUInt32BigEndian(from: data)
        self.startTime = try Self.startTimeField.readUInt32BigEndian(from: data)
        self.stopTime = try Self.stopTimeField.readUInt32BigEndian(from: data)
        self.volume = try Self.volumeField.readUInt32BigEndian(from: data)
        self.shuffleFlag = try Self.shuffleFlagField.readUInt32BigEndian(from: data)
        self.bookmarkFlag = try Self.bookmarkFlagField.readUInt32BigEndian(from: data)
        
        // Read filename (starts at offset 28, null-terminated)
        let filenameData = data.subdata(in: 28..<data.count)
        if let nullIndex = filenameData.firstIndex(of: 0) {
            let nameData = filenameData.prefix(upTo: nullIndex)
            self.filename = String(data: nameData, encoding: .utf8) ?? ""
        } else {
            self.filename = String(data: filenameData, encoding: .utf8) ?? ""
        }
    }
}

extension iTunesSDTrack {
    /// Track duration in seconds
    var durationInSeconds: Double {
        return Double(length) / 1000.0
    }

    /// File extension
    var fileExtension: String {
        let url = URL(fileURLWithPath: filename)
        return url.pathExtension.lowercased()
    }

    /// Display name (filename without extension)
    var displayName: String {
        let url = URL(fileURLWithPath: filename)
        return url.deletingPathExtension().lastPathComponent
    }
}

extension iTunesSDTrack {
    static let lengthField = IPKBinaryField(offset: 0, length: 4)
    static let fileTypeField = IPKBinaryField(offset: 4, length: 4)
    static let startTimeField = IPKBinaryField(offset: 8, length: 4)
    static let stopTimeField = IPKBinaryField(offset: 12, length: 4)
    static let volumeField = IPKBinaryField(offset: 16, length: 4)
    static let shuffleFlagField = IPKBinaryField(offset: 20, length: 4)
    static let bookmarkFlagField = IPKBinaryField(offset: 24, length: 4)
}
