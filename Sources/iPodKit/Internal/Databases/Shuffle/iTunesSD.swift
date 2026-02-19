//
//  iTunesSD.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// iTunesSD File parser for iPod Shuffle devices
/// 
/// The iTunesSD file is the main database file used by iPod Shuffle devices.
/// It uses big-endian format and is simpler than the standard iTunesDB.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#iTunesSD
internal struct iTunesSD: IPKParseable, Sendable {
    // Binary fields
    public let headerLength: UInt32
    public let versionNumber: UInt32
    public let numberOfTracks: UInt32
    
    // Track entries
    public let tracks: [iTunesSDTrack]
    
    public init(from data: Data) throws {
        // Check for big-endian format identifier
        guard data.count >= 4 else {
            throw IPKParsingError.insufficientData
        }
        
        let identifier = data.prefix(4)
        let expectedData = Data([0x42, 0x44, 0x00, 0x00])
        guard identifier == expectedData else { // "BD\0\0"
            let foundString = identifier.map { String(format: "%02X", $0) }.joined()
            let expectedString = expectedData.map { String(format: "%02X", $0) }.joined()
            throw IPKParsingError.invalidMagicNumber(expected: expectedString, found: foundString)
        }
        
        // Parse header fields (big-endian)
        self.headerLength = try Self.HeaderLength().readUInt32BigEndian(from: data)
        _ = try Self.TotalLength().readUInt32BigEndian(from: data)
        self.versionNumber = try Self.VersionNumber().readUInt32BigEndian(from: data)
        self.numberOfTracks = try Self.NumberOfTracks().readUInt32BigEndian(from: data)
        
        // Parse track entries
        var tracks: [iTunesSDTrack] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfTracks {
            guard offset + 512 <= data.count else { break } // Each entry is 512 bytes
            
            let trackData = data.subdata(in: offset..<(offset + 512))
            let track = try iTunesSDTrack(from: trackData)
            tracks.append(track)
            
            offset += 512
        }
        
        self.tracks = tracks
    }
}

// MARK: - iTunesSD Track Entry
internal struct iTunesSDTrack: IPKParseable, Sendable {
    // Binary fields (all big-endian)
    public let length: UInt32
    public let startTime: UInt32
    public let stopTime: UInt32
    public let volume: UInt32
    public let shuffleFlag: UInt32
    public let bookmarkFlag: UInt32
    public let filename: String
    
    public init(from data: Data) throws {
        guard data.count >= 512 else {
            throw IPKParsingError.insufficientData
        }
        
        // Read binary fields (big-endian)
        self.length = try Self.Length().readUInt32BigEndian(from: data)
        _ = try Self.FileType().readUInt32BigEndian(from: data)
        self.startTime = try Self.StartTime().readUInt32BigEndian(from: data)
        self.stopTime = try Self.StopTime().readUInt32BigEndian(from: data)
        self.volume = try Self.Volume().readUInt32BigEndian(from: data)
        self.shuffleFlag = try Self.ShuffleFlag().readUInt32BigEndian(from: data)
        self.bookmarkFlag = try Self.BookmarkFlag().readUInt32BigEndian(from: data)
        
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

// MARK: - Convenience Properties
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

// MARK: - Public API
extension iTunesSD {
    /// Total duration of all tracks
    var totalDuration: Double {
        return tracks.reduce(0) { $0 + $1.durationInSeconds }
    }
    
    /// Formatted total duration
    var totalDurationFormatted: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Get all unique file extensions
    /// - Returns: Array of unique file extensions
    func uniqueFileExtensions() -> [String] {
        let extensions = tracks.map { $0.fileExtension }
        return Array(Set(extensions)).sorted()
    }
}

// MARK: - Field Definitions with Big-Endian Support
extension iTunesSD {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct VersionNumber: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct NumberOfTracks: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
}

extension iTunesSDTrack {
    struct Length: IPKField {
        var offset: Int { 0 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct FileType: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct StartTime: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct StopTime: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct Volume: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct ShuffleFlag: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
    
    struct BookmarkFlag: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
        
        func readUInt32BigEndian(from data: Data) throws -> UInt32 {
            guard offset >= 0 && offset + 3 < data.count else {
                throw IPKParsingError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
}