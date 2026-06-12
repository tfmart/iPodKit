//
//  TestFixtures.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation
@testable import iPodKit

/// Builds an in-memory Track for DTO and filter tests.
func makeTrack(
    id: UInt64 = 1,
    title: String? = nil,
    artist: String? = nil,
    album: String? = nil,
    genre: String? = nil,
    duration: TimeInterval = 180,
    playCount: Int = 0,
    lastPlayed: Date? = nil,
    dateAdded: Date? = nil
) -> Track {
    Track(
        id: id,
        index: 0,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        composer: nil,
        comment: nil,
        grouping: nil,
        location: nil,
        duration: duration,
        fileSize: 0,
        bitrate: nil,
        sampleRate: nil,
        trackNumber: nil,
        totalTracks: nil,
        year: nil,
        playCount: playCount,
        skipCount: 0,
        rating: 0,
        lastPlayed: lastPlayed,
        lastSkipped: nil,
        bookmark: nil,
        dateAdded: dateAdded,
        dateModified: nil
    )
}
