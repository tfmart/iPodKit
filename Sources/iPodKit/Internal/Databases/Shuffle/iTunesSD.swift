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
    let headerLength: UInt32
    let versionNumber: UInt32
    let numberOfTracks: UInt32
    
    // Track entries
    let tracks: [iTunesSDTrack]
    
    init(from data: Data) throws {
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
        self.headerLength = try Self.headerLengthField.readUInt32BigEndian(from: data)
        _ = try Self.totalLengthField.readUInt32BigEndian(from: data)
        self.versionNumber = try Self.versionNumberField.readUInt32BigEndian(from: data)
        self.numberOfTracks = try Self.numberOfTracksField.readUInt32BigEndian(from: data)
        
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

// MARK: - Internal API
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
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let versionNumberField = IPKBinaryField(offset: 12, length: 4)
    static let numberOfTracksField = IPKBinaryField(offset: 16, length: 4)
}
