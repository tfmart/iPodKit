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
internal struct PlayCounts: IPKParseable, Sendable {
    // Binary fields
    let headerLength: UInt32
    let entryLength: UInt32
    let numberOfEntries: UInt32
    
    // Play count entries
    let entries: [PlayCountEntry]
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhdp")
        
        // Parse header fields
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.entryLength = try Self.entryLengthField.readUInt32(from: data)
        self.numberOfEntries = try Self.numberOfEntriesField.readUInt32(from: data)
        
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

// MARK: - Internal API
extension PlayCounts {
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
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let entryLengthField = IPKBinaryField(offset: 8, length: 4)
    static let numberOfEntriesField = IPKBinaryField(offset: 12, length: 4)
}
