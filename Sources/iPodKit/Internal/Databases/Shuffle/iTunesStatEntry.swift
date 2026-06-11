//
//  iTunesStatEntry.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

internal struct iTunesStatEntry: IPKParseable, Sendable {
    // Binary fields (little-endian)
    let playCount: UInt32
    let lastPlayed: UInt32
    let rating: UInt32
    let skipCount: UInt32
    let lastSkipped: UInt32
    let bookmark: UInt32
    
    init(from data: Data) throws {
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

extension iTunesStatEntry {
    /// Last played date. The stored value is device-local wall-clock time.
    func lastPlayedDate(in timeZone: TimeZone) -> Date? {
        IPKTimestamp.date(fromMacTimestamp: lastPlayed, in: timeZone)
    }

    /// Last skipped date. The stored value is device-local wall-clock time.
    func lastSkippedDate(in timeZone: TimeZone) -> Date? {
        IPKTimestamp.date(fromMacTimestamp: lastSkipped, in: timeZone)
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
    
    /// Whether this track has a rating
    var hasRating: Bool {
        return rating > 0
    }
}
