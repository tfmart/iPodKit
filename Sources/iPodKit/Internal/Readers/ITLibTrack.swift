//
//  ITLibTrack.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

internal struct ITLibTrack: Sendable {
    let pid: Int64
    let title: String
    let artist: String
    let album: String
    let totalTimeMs: Double
    let playCount: Int
    let datePlayed: Int64  // Core Data timestamp (seconds since Jan 1, 2001)

    /// Last played date converted from Core Data timestamp
    var lastPlayedDate: Date? {
        guard datePlayed > 0 else { return nil }
        // Core Data timestamp: seconds since Jan 1, 2001
        // Jan 1, 2001 00:00:00 UTC = Unix timestamp 978307200
        let coreDataEpochOffset: TimeInterval = 978307200
        return Date(timeIntervalSince1970: Double(datePlayed) + coreDataEpochOffset)
    }

    /// Track duration in seconds
    var durationInSeconds: Double {
        return totalTimeMs / 1000.0
    }
}
