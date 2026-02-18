//
//  iTunesShuffle.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// iTunesShuffle File parser for iPod Shuffle devices
/// 
/// The iTunesShuffle file contains the shuffled track order list to maintain
/// a consistent shuffle sequence across power cycles and syncs.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#iTunesShuffle
struct iTunesShuffle: IPKParseable, Sendable {
    // Binary fields
    public let numberOfTracks: UInt32
    
    // Shuffled track indexes
    public let shuffledIndexes: [UInt32]
    
    public init(from data: Data) throws {
        guard data.count >= 4 else {
            throw IPKError.insufficientData
        }
        
        // Parse number of tracks (little-endian)
        self.numberOfTracks = try data.readUInt32(at: 0)
        
        // Parse shuffled track indexes
        var indexes: [UInt32] = []
        var offset = 4
        
        for _ in 0..<numberOfTracks {
            guard offset + 4 <= data.count else { break }
            
            let trackIndex = try data.readUInt32(at: offset)
            indexes.append(trackIndex)
            offset += 4
        }
        
        self.shuffledIndexes = indexes
    }
}

// MARK: - Convenience Properties
extension iTunesShuffle {
    /// Get the number of tracks in the shuffle sequence
    var count: Int {
        return shuffledIndexes.count
    }

    /// Check if shuffle sequence is valid (no duplicates, sequential from 0)
    var isValid: Bool {
        let sortedIndexes = shuffledIndexes.sorted()
        let expectedIndexes = Array(0..<UInt32(shuffledIndexes.count))
        return sortedIndexes == expectedIndexes
    }

    /// Get duplicate track indexes (invalid shuffle sequences)
    var duplicateIndexes: [UInt32] {
        var seen = Set<UInt32>()
        var duplicates = Set<UInt32>()
        
        for index in shuffledIndexes {
            if seen.contains(index) {
                duplicates.insert(index)
            } else {
                seen.insert(index)
            }
        }
        
        return Array(duplicates).sorted()
    }
    
    /// Get missing track indexes (invalid shuffle sequences)
    var missingIndexes: [UInt32] {
        let expectedIndexes = Set(0..<UInt32(numberOfTracks))
        let actualIndexes = Set(shuffledIndexes)
        return Array(expectedIndexes.subtracting(actualIndexes)).sorted()
    }
}

// MARK: - Public API
extension iTunesShuffle {
    /// Get statistics about the shuffle sequence
    /// - Returns: Dictionary containing shuffle statistics
    func shuffleStatistics() -> [String: Any] {
        return [
            "totalTracks": numberOfTracks,
            "shuffledTracks": shuffledIndexes.count,
            "isValid": isValid,
            "duplicateCount": duplicateIndexes.count,
            "missingCount": missingIndexes.count,
            "firstTrack": shuffledIndexes.first as Any,
            "lastTrack": shuffledIndexes.last as Any,
            "averagePosition": shuffledIndexes.isEmpty ? 0 : Double(shuffledIndexes.reduce(0, +)) / Double(shuffledIndexes.count)
        ]
    }
}