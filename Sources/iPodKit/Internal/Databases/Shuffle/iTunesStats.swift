//
//  iTunesStats.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// iTunesStats File parser for iPod Shuffle devices
/// 
/// The iTunesStats file is equivalent to the Play Counts file for iPod Shuffle.
/// It stores play counts, ratings, and last played times in little-endian format.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#iTunesStats
internal struct iTunesStats: IPKParseable, Sendable {
    // Binary fields
    public let numberOfEntries: UInt32
    public let entryLength: UInt32
    
    // Stat entries
    public let entries: [iTunesStatEntry]
    
    public init(from data: Data) throws {
        guard data.count >= 8 else {
            throw IPKParsingError.insufficientData
        }
        
        // Parse header fields (little-endian)
        self.numberOfEntries = try data.readUInt32(at: 0)
        self.entryLength = try data.readUInt32(at: 4)
        
        // Parse stat entries
        var entries: [iTunesStatEntry] = []
        var offset = 8
        
        for _ in 0..<numberOfEntries {
            guard offset + Int(entryLength) <= data.count else { break }
            
            let entryData = data.subdata(in: offset..<(offset + Int(entryLength)))
            let entry = try iTunesStatEntry(from: entryData)
            entries.append(entry)
            
            offset += Int(entryLength)
        }
        
        self.entries = entries
    }
}

// MARK: - iTunes Stat Entry
internal struct iTunesStatEntry: IPKParseable, Sendable {
    // Binary fields (little-endian)
    public let playCount: UInt32
    public let lastPlayed: UInt32
    public let rating: UInt32
    public let skipCount: UInt32
    public let lastSkipped: UInt32
    public let bookmark: UInt32
    
    public init(from data: Data) throws {
        guard data.count >= 24 else {
            throw IPKParsingError.insufficientData
        }
        
        // Read fields (little-endian)
        self.playCount = try data.readUInt32(at: 0)
        self.lastPlayed = try data.readUInt32(at: 4)
        self.rating = try data.readUInt32(at: 8)
        self.skipCount = try data.readUInt32(at: 12)
        self.lastSkipped = try data.readUInt32(at: 16)
        self.bookmark = try data.readUInt32(at: 20)
    }
}

// MARK: - Convenience Properties
extension iTunesStatEntry {
    /// Last played date converted from Mac epoch timestamp
    var lastPlayedDate: Date? {
        guard lastPlayed > 0 else { return nil }
        let macEpochOffset: TimeInterval = 2082844800
        let unixTimestamp = TimeInterval(lastPlayed) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }
    
    /// Last skipped date converted from Mac epoch timestamp
    var lastSkippedDate: Date? {
        guard lastSkipped > 0 else { return nil }
        let macEpochOffset: TimeInterval = 2082844800
        let unixTimestamp = TimeInterval(lastSkipped) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }
    
    /// Star rating (0-5)
    var starRating: Int {
        return Int(rating) / 20
    }
    
    /// Bookmark time in seconds
    var bookmarkTimeInSeconds: Double {
        return Double(bookmark) / 1000.0
    }

    /// Whether this track has been played
    var hasBeenPlayed: Bool {
        return playCount > 0
    }
    
    /// Whether this track has been skipped
    var hasBeenSkipped: Bool {
        return skipCount > 0
    }
    
    /// Whether this track has a bookmark
    var hasBookmark: Bool {
        return bookmark > 0
    }

    /// Whether this track has a rating
    var hasRating: Bool {
        return rating > 0
    }
}

// MARK: - Public API
extension iTunesStats {
    /// Get stat entry for a specific track by index
    /// - Parameter trackIndex: Zero-based track index
    /// - Returns: Stat entry if found
    func statEntry(for trackIndex: Int) -> iTunesStatEntry? {
        guard trackIndex >= 0 && trackIndex < entries.count else { return nil }
        return entries[trackIndex]
    }

    /// Total play count across all tracks
    var totalPlayCount: UInt64 {
        return entries.reduce(0) { $0 + UInt64($1.playCount) }
    }

    /// Average star rating across all rated tracks
    var averageStarRating: Double {
        let ratedEntries = entries.filter { $0.hasRating }
        guard !ratedEntries.isEmpty else { return 0 }
        let totalRating = ratedEntries.reduce(0) { $0 + $1.starRating }
        return Double(totalRating) / Double(ratedEntries.count)
    }

    /// Number of tracks with play counts
    var playedTrackCount: Int {
        return entries.filter { $0.hasBeenPlayed }.count
    }

    /// Number of tracks with skip counts
    var skippedTrackCount: Int {
        return entries.filter { $0.hasBeenSkipped }.count
    }

    /// Number of tracks with ratings
    var ratedTrackCount: Int {
        return entries.filter { $0.hasRating }.count
    }
}