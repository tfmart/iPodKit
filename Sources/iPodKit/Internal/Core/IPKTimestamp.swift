//
//  IPKTimestamp.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// Central timestamp conversion for all iPod database formats.
///
/// iPod databases store dates in two different ways, and they are **not**
/// anchored to the same reference:
///
/// - **Binary databases** (iTunesDB, Play Counts, iTunesStats, playlists) use
///   Mac epoch (seconds since 1904-01-01) holding the device's **local
///   wall-clock time**. Decoding it as UTC produces a `Date` that is off by
///   the device's UTC offset.
/// - **SQLite databases** (`iTunes Library.itlp`) use Apple/Core Data epoch
///   (seconds since 2001-01-01) in **true UTC**.
///
/// Verified empirically: the same play is stored in `Play Counts` and
/// `Dynamic.itdb` with values that differ by exactly the device's UTC offset.
///
/// All conversions must go through this type so every public `Date` represents
/// the same absolute instant regardless of which database it came from.
internal enum IPKTimestamp {

    /// Seconds between the Mac epoch (1904-01-01) and the Unix epoch (1970-01-01).
    static let macEpochOffset: TimeInterval = 2082844800

    /// Convert a Mac-epoch wall-clock timestamp to an absolute instant.
    ///
    /// - Parameters:
    ///   - timestamp: Seconds since 1904-01-01 in the device's local time.
    ///   - timeZone: The time zone the device's clock was set to.
    /// - Returns: The absolute instant, or `nil` if the timestamp is zero.
    static func date(fromMacTimestamp timestamp: UInt32, in timeZone: TimeZone) -> Date? {
        guard timestamp > 0 else { return nil }
        let wallClock = Date(timeIntervalSince1970: TimeInterval(timestamp) - macEpochOffset)
        // The wall-clock reading is not an instant yet, so resolve the UTC
        // offset twice to land on the correct side of a DST transition.
        var offset = TimeInterval(timeZone.secondsFromGMT(for: wallClock))
        let firstGuess = wallClock.addingTimeInterval(-offset)
        offset = TimeInterval(timeZone.secondsFromGMT(for: firstGuess))
        return wallClock.addingTimeInterval(-offset)
    }

    /// Convert an Apple-epoch (Core Data) UTC timestamp to an absolute instant.
    ///
    /// - Parameter timestamp: Seconds since 2001-01-01 00:00:00 UTC.
    /// - Returns: The absolute instant, or `nil` if the timestamp is not positive.
    static func date(fromAppleTimestamp timestamp: Int64) -> Date? {
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
    }
}
