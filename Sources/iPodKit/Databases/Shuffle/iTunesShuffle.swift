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
public struct iTunesShuffle: IPKParseable {
    let id: String = ""
    
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
public extension iTunesShuffle {
    /// Check if the shuffle list is empty
    var isEmpty: Bool {
        return shuffledIndexes.isEmpty
    }
    
    /// Get the number of tracks in the shuffle sequence
    var count: Int {
        return shuffledIndexes.count
    }
    
    /// Get track indexes as an array for easy iteration
    var tracks: [UInt32] {
        return shuffledIndexes
    }
    
    /// Check if shuffle sequence is valid (no duplicates, sequential from 0)
    var isValid: Bool {
        let sortedIndexes = shuffledIndexes.sorted()
        let expectedIndexes = Array(0..<UInt32(shuffledIndexes.count))
        return sortedIndexes == expectedIndexes
    }
    
    /// Get the original (non-shuffled) order
    /// - Returns: Array mapping shuffled position to original track index
    var originalOrder: [UInt32] {
        var order = Array(repeating: UInt32(0), count: shuffledIndexes.count)
        for (shuffledPosition, originalIndex) in shuffledIndexes.enumerated() {
            if originalIndex < shuffledIndexes.count {
                order[Int(originalIndex)] = UInt32(shuffledPosition)
            }
        }
        return order
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
public extension iTunesShuffle {
    /// Get the shuffled position for a given original track index
    /// - Parameter originalIndex: Original track index
    /// - Returns: Shuffled position if found
    func shuffledPosition(for originalIndex: UInt32) -> Int? {
        return shuffledIndexes.firstIndex(of: originalIndex)
    }
    
    /// Get the original track index for a given shuffled position
    /// - Parameter shuffledPosition: Position in the shuffled sequence
    /// - Returns: Original track index if valid position
    func originalIndex(at shuffledPosition: Int) -> UInt32? {
        guard shuffledPosition >= 0 && shuffledPosition < shuffledIndexes.count else { return nil }
        return shuffledIndexes[shuffledPosition]
    }
    
    /// Get a range of shuffled track indexes
    /// - Parameter range: Range of positions to retrieve
    /// - Returns: Array of track indexes in the specified range
    func shuffledIndexes(in range: Range<Int>) -> [UInt32] {
        let clampedRange = max(0, range.lowerBound)..<min(shuffledIndexes.count, range.upperBound)
        return Array(shuffledIndexes[clampedRange])
    }
    
    /// Get the next track index in shuffle order
    /// - Parameter currentIndex: Current track index
    /// - Returns: Next track index, or nil if current is last or not found
    func nextTrackIndex(after currentIndex: UInt32) -> UInt32? {
        guard let currentPosition = shuffledPosition(for: currentIndex) else { return nil }
        let nextPosition = currentPosition + 1
        return originalIndex(at: nextPosition)
    }
    
    /// Get the previous track index in shuffle order
    /// - Parameter currentIndex: Current track index
    /// - Returns: Previous track index, or nil if current is first or not found
    func previousTrackIndex(before currentIndex: UInt32) -> UInt32? {
        guard let currentPosition = shuffledPosition(for: currentIndex) else { return nil }
        let previousPosition = currentPosition - 1
        return originalIndex(at: previousPosition)
    }
    
    /// Create a new shuffle sequence with the same tracks
    /// - Returns: New iTunesShuffle with randomized order
    func reshuffle() -> iTunesShuffle {
        var newIndexes = shuffledIndexes
        newIndexes.shuffle()
        
        // Create new data
        var data = Data()
        withUnsafeBytes(of: numberOfTracks.littleEndian) { data.append(contentsOf: $0) }
        for index in newIndexes {
            withUnsafeBytes(of: index.littleEndian) { data.append(contentsOf: $0) }
        }
        
        return try! iTunesShuffle(from: data)
    }
    
    /// Verify the integrity of the shuffle sequence
    /// - Returns: Tuple containing validity status and issues found
    func verifyIntegrity() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        if shuffledIndexes.count != numberOfTracks {
            issues.append("Index count (\(shuffledIndexes.count)) doesn't match declared track count (\(numberOfTracks))")
        }
        
        let duplicates = duplicateIndexes
        if !duplicates.isEmpty {
            issues.append("Duplicate indexes found: \(duplicates)")
        }
        
        let missing = missingIndexes
        if !missing.isEmpty {
            issues.append("Missing indexes: \(missing)")
        }
        
        let outOfRange = shuffledIndexes.filter { $0 >= numberOfTracks }
        if !outOfRange.isEmpty {
            issues.append("Out of range indexes: \(outOfRange)")
        }
        
        return (isValid: issues.isEmpty, issues: issues)
    }
    
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