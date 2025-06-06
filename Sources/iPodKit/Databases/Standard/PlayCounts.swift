//
//  PlayCounts.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

/// Play Counts File parser for iPod database
/// 
/// The Play Counts file stores play counts, ratings, and last played times
/// since the last sync with iTunes. It gets rebuilt whenever the iTunesDB changes.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Play_Counts_File
public struct PlayCounts: IPKParseable {
    let id: String = "mhdp"
    
    // Binary fields
    public let headerLength: UInt32
    public let entryLength: UInt32
    public let numberOfEntries: UInt32
    
    // Play count entries
    public let entries: [PlayCountEntry]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhdp")
        
        // Parse header fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.entryLength = try Self.EntryLength().readUInt32(from: data)
        self.numberOfEntries = try Self.NumberOfEntries().readUInt32(from: data)
        
        // Parse entries
        var entries: [PlayCountEntry] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfEntries {
            guard offset + Int(entryLength) <= data.count else { break }
            
            let entryData = data.subdata(in: offset..<(offset + Int(entryLength)))
            let entry = try PlayCountEntry(from: entryData)
            entries.append(entry)
            
            offset += Int(entryLength)
        }
        
        self.entries = entries
    }
}

// MARK: - Play Count Entry
public struct PlayCountEntry: IPKParseable {
    let id: String = "mhpo"
    
    // Binary fields
    public let playCount: UInt32
    public let lastPlayed: UInt32
    public let bookmarkTime: UInt32
    public let rating: UInt32
    public let skipCount: UInt32
    public let lastSkipped: UInt32
    
    public init(from data: Data) throws {
        // Note: Play count entries don't have magic numbers in some versions
        // We'll read the fields directly
        guard data.count >= 16 else {
            throw IPKError.insufficientData
        }
        
        self.playCount = try data.readUInt32(at: 0)
        self.lastPlayed = try data.readUInt32(at: 4)
        self.bookmarkTime = try data.readUInt32(at: 8)
        self.rating = try data.readUInt32(at: 12)
        
        // Skip count and last skipped are optional fields for newer firmware
        if data.count >= 24 {
            self.skipCount = try data.readUInt32(at: 20)
            self.lastSkipped = try data.readUInt32(at: 24)
        } else {
            self.skipCount = 0
            self.lastSkipped = 0
        }
    }
}

// MARK: - Convenience Properties
public extension PlayCountEntry {
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
    
    /// Formatted last played date string
    var lastPlayedFormatted: String {
        guard let date = lastPlayedDate else { return "Never played" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Formatted last skipped date string
    var lastSkippedFormatted: String {
        guard let date = lastSkippedDate else { return "Never skipped" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Star rating (0-5)
    var starRating: Int {
        return Int(rating) / 20
    }
    
    /// Bookmark time formatted as MM:SS
    var bookmarkTimeFormatted: String {
        let totalSeconds = Int(bookmarkTime / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Public API
public extension PlayCounts {
    /// Get play count entry for a specific track by index
    /// - Parameter trackIndex: Zero-based track index
    /// - Returns: Play count entry if found
    func playCountEntry(for trackIndex: Int) -> PlayCountEntry? {
        guard trackIndex >= 0 && trackIndex < entries.count else { return nil }
        return entries[trackIndex]
    }
    
    /// Get all entries that have been played at least once
    /// - Returns: Array of played entries with their indexes
    func playedEntries() -> [(index: Int, entry: PlayCountEntry)] {
        return entries.enumerated().compactMap { index, entry in
            entry.playCount > 0 ? (index, entry) : nil
        }
    }
    
    /// Get entries played after a specific date
    /// - Parameter date: Date to filter from
    /// - Returns: Array of recently played entries with their indexes
    func entries(playedAfter date: Date) -> [(index: Int, entry: PlayCountEntry)] {
        return entries.enumerated().compactMap { index, entry in
            guard let lastPlayed = entry.lastPlayedDate else { return nil }
            return lastPlayed > date ? (index, entry) : nil
        }
    }
    
    /// Get most played entries
    /// - Parameter limit: Number of entries to return
    /// - Returns: Array of most played entries with their indexes
    func mostPlayedEntries(limit: Int = 10) -> [(index: Int, entry: PlayCountEntry)] {
        return entries.enumerated()
            .filter { $0.element.playCount > 0 }
            .sorted { $0.element.playCount > $1.element.playCount }
            .prefix(limit)
            .map { (index: $0.offset, entry: $0.element) }
    }
}

// MARK: - Field Definitions
extension PlayCounts {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct EntryLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfEntries: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}
