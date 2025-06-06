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
public struct iTunesStats: IPKParseable {
    let id: String = ""
    
    // Binary fields
    public let numberOfEntries: UInt32
    public let entryLength: UInt32
    
    // Stat entries
    public let entries: [iTunesStatEntry]
    
    public init(from data: Data) throws {
        guard data.count >= 8 else {
            throw IPKError.insufficientData
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
public struct iTunesStatEntry: IPKParseable {
    let id: String = ""
    
    // Binary fields (little-endian)
    public let playCount: UInt32
    public let lastPlayed: UInt32
    public let rating: UInt32
    public let skipCount: UInt32
    public let lastSkipped: UInt32
    public let bookmark: UInt32
    
    public init(from data: Data) throws {
        guard data.count >= 24 else {
            throw IPKError.insufficientData
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
public extension iTunesStatEntry {
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
    
    /// Bookmark time in seconds
    var bookmarkTimeInSeconds: Double {
        return Double(bookmark) / 1000.0
    }
    
    /// Bookmark time formatted as MM:SS
    var bookmarkTimeFormatted: String {
        let totalSeconds = Int(bookmarkTimeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
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
    
    /// Play to skip ratio (useful for determining track popularity)
    var playToSkipRatio: Double {
        guard skipCount > 0 else { return playCount > 0 ? Double.infinity : 0 }
        return Double(playCount) / Double(skipCount)
    }
}

// MARK: - Public API
public extension iTunesStats {
    /// Get stat entry for a specific track by index
    /// - Parameter trackIndex: Zero-based track index
    /// - Returns: Stat entry if found
    func statEntry(for trackIndex: Int) -> iTunesStatEntry? {
        guard trackIndex >= 0 && trackIndex < entries.count else { return nil }
        return entries[trackIndex]
    }
    
    /// Get all entries that have been played at least once
    /// - Returns: Array of played entries with their indexes
    func playedEntries() -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated().compactMap { index, entry in
            entry.hasBeenPlayed ? (index, entry) : nil
        }
    }
    
    /// Get entries played after a specific date
    /// - Parameter date: Date to filter from
    /// - Returns: Array of recently played entries with their indexes
    func entries(playedAfter date: Date) -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated().compactMap { index, entry in
            guard let lastPlayed = entry.lastPlayedDate else { return nil }
            return lastPlayed > date ? (index, entry) : nil
        }
    }
    
    /// Get most played entries
    /// - Parameter limit: Number of entries to return
    /// - Returns: Array of most played entries with their indexes
    func mostPlayedEntries(limit: Int = 10) -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated()
            .filter { $0.element.hasBeenPlayed }
            .sorted { $0.element.playCount > $1.element.playCount }
            .prefix(limit)
            .map { (index: $0.offset, entry: $0.element) }
    }
    
    /// Get most skipped entries
    /// - Parameter limit: Number of entries to return
    /// - Returns: Array of most skipped entries with their indexes
    func mostSkippedEntries(limit: Int = 10) -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated()
            .filter { $0.element.hasBeenSkipped }
            .sorted { $0.element.skipCount > $1.element.skipCount }
            .prefix(limit)
            .map { (index: $0.offset, entry: $0.element) }
    }
    
    /// Get entries with bookmarks
    /// - Returns: Array of bookmarked entries with their indexes
    func bookmarkedEntries() -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated().compactMap { index, entry in
            entry.hasBookmark ? (index, entry) : nil
        }
    }
    
    /// Get entries with ratings
    /// - Returns: Array of rated entries with their indexes
    func ratedEntries() -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated().compactMap { index, entry in
            entry.hasRating ? (index, entry) : nil
        }
    }
    
    /// Get entries by star rating
    /// - Parameter rating: Star rating (1-5)
    /// - Returns: Array of entries with the specified rating
    func entries(withStarRating rating: Int) -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated().compactMap { index, entry in
            entry.starRating == rating ? (index, entry) : nil
        }
    }
    
    /// Get entries with high play-to-skip ratio (popular tracks)
    /// - Parameter minimumRatio: Minimum play-to-skip ratio
    /// - Returns: Array of popular entries with their indexes
    func popularEntries(minimumRatio: Double = 2.0) -> [(index: Int, entry: iTunesStatEntry)] {
        return entries.enumerated().compactMap { index, entry in
            entry.playToSkipRatio >= minimumRatio ? (index, entry) : nil
        }
    }
    
    /// Total play count across all tracks
    var totalPlayCount: UInt64 {
        return entries.reduce(0) { $0 + UInt64($1.playCount) }
    }
    
    /// Total skip count across all tracks
    var totalSkipCount: UInt64 {
        return entries.reduce(0) { $0 + UInt64($1.skipCount) }
    }
    
    /// Overall play-to-skip ratio for the entire library
    var overallPlayToSkipRatio: Double {
        guard totalSkipCount > 0 else { return totalPlayCount > 0 ? Double.infinity : 0 }
        return Double(totalPlayCount) / Double(totalSkipCount)
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
    
    /// Number of tracks with bookmarks
    var bookmarkedTrackCount: Int {
        return entries.filter { $0.hasBookmark }.count
    }
    
    /// Number of tracks with ratings
    var ratedTrackCount: Int {
        return entries.filter { $0.hasRating }.count
    }
}