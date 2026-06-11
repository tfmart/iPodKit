//
//  PlayCountEntry.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

internal struct PlayCountEntry: IPKParseable, Sendable {
    // Binary fields
    let playCount: UInt32
    let lastPlayed: UInt32
    let bookmarkTime: UInt32
    let rating: UInt32
    let skipCount: UInt32
    let lastSkipped: UInt32
    
    init(from data: Data) throws {
        // Note: Play count entries don't have magic numbers in some versions
        // We'll read the fields directly
        guard data.count >= 16 else {
            throw IPKParsingError.insufficientData
        }
        
        self.playCount = try data.readUInt32(at: 0)
        self.lastPlayed = try data.readUInt32(at: 4)
        self.bookmarkTime = try data.readUInt32(at: 8)
        self.rating = try data.readUInt32(at: 12)
        
        // Skip count and last skipped are optional fields for newer firmware.
        if data.count >= 28 {
            self.skipCount = try data.readUInt32(at: 20)
            self.lastSkipped = try data.readUInt32(at: 24)
        } else {
            self.skipCount = 0
            self.lastSkipped = 0
        }
    }
}

extension PlayCountEntry {
    /// Last played date. The stored value is device-local wall-clock time.
    func lastPlayedDate(in timeZone: TimeZone) -> Date? {
        IPKTimestamp.date(fromMacTimestamp: lastPlayed, in: timeZone)
    }

    /// Last skipped date. The stored value is device-local wall-clock time.
    func lastSkippedDate(in timeZone: TimeZone) -> Date? {
        IPKTimestamp.date(fromMacTimestamp: lastSkipped, in: timeZone)
    }

    /// Formatted last played date string
    func lastPlayedFormatted(in timeZone: TimeZone) -> String {
        guard let date = lastPlayedDate(in: timeZone) else { return "Never played" }
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
