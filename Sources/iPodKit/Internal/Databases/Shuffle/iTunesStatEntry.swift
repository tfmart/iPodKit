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
    
    /// Whether this track has a rating
    var hasRating: Bool {
        return rating > 0
    }
}
