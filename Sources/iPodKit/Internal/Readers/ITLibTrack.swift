//
//  ITLibTrack.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

internal struct ITLibTrack: Sendable {
    // Identity and metadata (Library.itdb `item`)
    let pid: Int64
    let title: String
    let artist: String
    let album: String
    let albumArtist: String?
    let genre: String?
    let composer: String?
    let comment: String?
    let grouping: String?
    let totalTimeMs: Double
    let startTimeMs: Double
    let stopTimeMs: Double
    let trackNumber: Int
    let trackCount: Int
    let discNumber: Int
    let discCount: Int
    let year: Int
    let bpm: Int
    let isCompilation: Bool
    let mediaType: MediaType
    let dateModified: Int64  // Apple epoch (seconds since Jan 1, 2001, UTC)

    // Audio format (Library.itdb `avformat_info`)
    let bitrate: Int
    let sampleRate: Int

    // File location (Locations.itdb `location` joined with `base_location`)
    let location: String?
    let fileSize: Int64

    // Play stats (Dynamic.itdb `item_stats`)
    let playCount: Int
    let skipCount: Int
    let rating: Int  // 0-100
    let datePlayed: Int64  // Apple epoch, UTC
    let dateSkipped: Int64  // Apple epoch, UTC
    let bookmarkTimeMs: Double

    /// Last played date. The stored value is true UTC, so no time zone is needed.
    var lastPlayedDate: Date? {
        IPKTimestamp.date(fromAppleTimestamp: datePlayed)
    }

    /// Last skipped date. The stored value is true UTC, so no time zone is needed.
    var lastSkippedDate: Date? {
        IPKTimestamp.date(fromAppleTimestamp: dateSkipped)
    }

    /// Date the track was last modified. The stored value is true UTC.
    var dateModifiedDate: Date? {
        IPKTimestamp.date(fromAppleTimestamp: dateModified)
    }

    /// Track duration in seconds
    var durationInSeconds: Double {
        return totalTimeMs / 1000.0
    }

    /// Star rating (0-5)
    var starRating: Int {
        return rating / 20
    }
}
