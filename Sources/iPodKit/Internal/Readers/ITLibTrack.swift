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

    /// Last played date. The stored value is true UTC, so no time zone is needed.
    var lastPlayedDate: Date? {
        IPKTimestamp.date(fromAppleTimestamp: datePlayed)
    }

    /// Track duration in seconds
    var durationInSeconds: Double {
        return totalTimeMs / 1000.0
    }
}
