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
    let numberOfEntries: UInt32
    let entryLength: UInt32
    
    // Stat entries
    let entries: [iTunesStatEntry]
    
    init(from data: Data) throws {
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

// MARK: - Internal API
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
