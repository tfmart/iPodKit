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
public struct iTunesSD: IPKParseable {
    let id: String = "BD\0\0" // Big-endian format identifier
    
    // Binary fields
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let versionNumber: UInt32
    public let numberOfTracks: UInt32
    
    // Track entries
    public let tracks: [iTunesSDTrack]
    
    public init(from data: Data) throws {
        // Check for big-endian format identifier
        guard data.count >= 4 else {
            throw IPKError.insufficientData
        }
        
        let identifier = data.prefix(4)
        let expectedData = Data([0x42, 0x44, 0x00, 0x00])
        guard identifier == expectedData else { // "BD\0\0"
            let foundString = identifier.map { String(format: "%02X", $0) }.joined()
            let expectedString = expectedData.map { String(format: "%02X", $0) }.joined()
            throw IPKError.invalidMagicNumber(expected: expectedString, found: foundString)
        }
        
        // Parse header fields (big-endian)
        self.headerLength = try Self.HeaderLength().readUInt32BigEndian(from: data)
        self.totalLength = try Self.TotalLength().readUInt32BigEndian(from: data)
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
public struct iTunesSDTrack: IPKParseable {
    let id: String = ""
    
    // Binary fields (all big-endian)
    public let length: UInt32
    public let fileType: UInt32
    public let startTime: UInt32
    public let stopTime: UInt32
    public let volume: UInt32
    public let shuffleFlag: UInt32
    public let bookmarkFlag: UInt32
    public let filename: String
    
    public init(from data: Data) throws {
        guard data.count >= 512 else {
            throw IPKError.insufficientData
        }
        
        // Read binary fields (big-endian)
        self.length = try Self.Length().readUInt32BigEndian(from: data)
        self.fileType = try Self.FileType().readUInt32BigEndian(from: data)
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
public extension iTunesSDTrack {
    /// Track duration in seconds
    var durationInSeconds: Double {
        return Double(length) / 1000.0
    }
    
    /// Track duration formatted as MM:SS
    var durationFormatted: String {
        let totalSeconds = Int(durationInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Start time in seconds
    var startTimeInSeconds: Double {
        return Double(startTime) / 1000.0
    }
    
    /// Stop time in seconds
    var stopTimeInSeconds: Double {
        return Double(stopTime) / 1000.0
    }
    
    /// Start time formatted as MM:SS
    var startTimeFormatted: String {
        let totalSeconds = Int(startTimeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Stop time formatted as MM:SS
    var stopTimeFormatted: String {
        let totalSeconds = Int(stopTimeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Volume as percentage (0-100)
    var volumePercentage: Int {
        return min(100, Int((Double(volume) / 255.0) * 100))
    }
    
    /// Whether shuffle is enabled for this track
    var isShuffleEnabled: Bool {
        return shuffleFlag != 0
    }
    
    /// Whether bookmark is enabled for this track
    var isBookmarkEnabled: Bool {
        return bookmarkFlag != 0
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
    
    /// Check if this is an MP3 file
    var isMP3: Bool {
        return fileExtension == "mp3"
    }
    
    /// Check if this is an AAC file
    var isAAC: Bool {
        return fileExtension == "aac" || fileExtension == "m4a"
    }
}

// MARK: - Public API
public extension iTunesSD {
    /// Get track by filename
    /// - Parameter filename: Filename to search for
    /// - Returns: Track if found
    func track(withFilename filename: String) -> iTunesSDTrack? {
        return tracks.first { $0.filename == filename }
    }
    
    /// Get tracks by file extension
    /// - Parameter extension: File extension to filter by
    /// - Returns: Array of matching tracks
    func tracks(withExtension extension: String) -> [iTunesSDTrack] {
        return tracks.filter { $0.fileExtension == `extension`.lowercased() }
    }
    
    /// Get MP3 tracks
    /// - Returns: Array of MP3 tracks
    func mp3Tracks() -> [iTunesSDTrack] {
        return tracks.filter { $0.isMP3 }
    }
    
    /// Get AAC tracks
    /// - Returns: Array of AAC tracks
    func aacTracks() -> [iTunesSDTrack] {
        return tracks.filter { $0.isAAC }
    }
    
    /// Get tracks with shuffle enabled
    /// - Returns: Array of shuffle-enabled tracks
    func shuffleTracks() -> [iTunesSDTrack] {
        return tracks.filter { $0.isShuffleEnabled }
    }
    
    /// Get tracks with bookmarks
    /// - Returns: Array of bookmarked tracks
    func bookmarkedTracks() -> [iTunesSDTrack] {
        return tracks.filter { $0.isBookmarkEnabled }
    }
    
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
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
                throw IPKError.invalidOffset(offset)
            }
            return (UInt32(data[offset]) << 24) |
                   (UInt32(data[offset + 1]) << 16) |
                   (UInt32(data[offset + 2]) << 8) |
                   UInt32(data[offset + 3])
        }
    }
}