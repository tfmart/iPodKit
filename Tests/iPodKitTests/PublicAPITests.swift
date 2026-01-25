//
//  PublicAPITests.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Testing
import Foundation
@testable import iPodKit

// MARK: - Track Model Tests

@Test func testTrackEquatable() async throws {
    let track1 = Track(
        id: 123,
        index: 0,
        title: "Song A",
        artist: nil,
        album: nil,
        genre: nil,
        composer: nil,
        comment: nil,
        grouping: nil,
        location: nil,
        duration: 180,
        fileSize: 0,
        bitrate: 0,
        sampleRate: 0,
        trackNumber: 0,
        totalTracks: 0,
        year: 0,
        playCount: 0,
        skipCount: 0,
        rating: 0,
        lastPlayed: nil,
        lastSkipped: nil,
        bookmark: nil,
        dateAdded: nil,
        dateModified: nil
    )

    // Same ID, different metadata
    let track2 = Track(
        id: 123,
        index: 1,
        title: "Song B",
        artist: "Different Artist",
        album: nil,
        genre: nil,
        composer: nil,
        comment: nil,
        grouping: nil,
        location: nil,
        duration: 300,
        fileSize: 0,
        bitrate: 0,
        sampleRate: 0,
        trackNumber: 0,
        totalTracks: 0,
        year: 0,
        playCount: 0,
        skipCount: 0,
        rating: 0,
        lastPlayed: nil,
        lastSkipped: nil,
        bookmark: nil,
        dateAdded: nil,
        dateModified: nil
    )

    // Different ID
    let track3 = Track(
        id: 456,
        index: 2,
        title: "Song A",
        artist: nil,
        album: nil,
        genre: nil,
        composer: nil,
        comment: nil,
        grouping: nil,
        location: nil,
        duration: 180,
        fileSize: 0,
        bitrate: 0,
        sampleRate: 0,
        trackNumber: 0,
        totalTracks: 0,
        year: 0,
        playCount: 0,
        skipCount: 0,
        rating: 0,
        lastPlayed: nil,
        lastSkipped: nil,
        bookmark: nil,
        dateAdded: nil,
        dateModified: nil
    )

    #expect(track1 == track2, "Tracks with same ID should be equal")
    #expect(track1 != track3, "Tracks with different IDs should not be equal")
}

// MARK: - Playlist Model Tests

@Test func testPlaylistDisplayName() async throws {
    let regularPlaylist = Playlist(
        id: 1,
        name: "My Favorites",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 10,
        trackIds: [],
        timestamp: nil
    )

    #expect(regularPlaylist.displayName == "My Favorites")

    let masterPlaylist = Playlist(
        id: 2,
        name: "Library",
        isMasterPlaylist: true,
        isPodcast: false,
        trackCount: 100,
        trackIds: [],
        timestamp: nil
    )

    #expect(masterPlaylist.displayName == "All Music")

    let untitledPlaylist = Playlist(
        id: 3,
        name: "",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 5,
        trackIds: [],
        timestamp: nil
    )

    #expect(untitledPlaylist.displayName == "Untitled Playlist")
}

@Test func testPlaylistIsEmpty() async throws {
    let emptyPlaylist = Playlist(
        id: 1,
        name: "Empty",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 0,
        trackIds: [],
        timestamp: nil
    )

    #expect(emptyPlaylist.isEmpty == true)

    let filledPlaylist = Playlist(
        id: 2,
        name: "Filled",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 10,
        trackIds: [1, 2, 3],
        timestamp: nil
    )

    #expect(filledPlaylist.isEmpty == false)
}

@Test func testPlaylistEquatable() async throws {
    let playlist1 = Playlist(
        id: 123,
        name: "Playlist A",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 5,
        trackIds: [],
        timestamp: nil
    )

    let playlist2 = Playlist(
        id: 123,
        name: "Playlist B",
        isMasterPlaylist: true,
        isPodcast: false,
        trackCount: 10,
        trackIds: [],
        timestamp: nil
    )

    let playlist3 = Playlist(
        id: 456,
        name: "Playlist A",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 5,
        trackIds: [],
        timestamp: nil
    )

    #expect(playlist1 == playlist2, "Playlists with same ID should be equal")
    #expect(playlist1 != playlist3, "Playlists with different IDs should not be equal")
}

// MARK: - iPod Façade Tests with Real Data

@Test func testiPodFacadeWithITunesDB() async throws {
    // Get the test resources directory
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let iTunesDBPath = resourceURL.path

    // Create an iPod instance using the internal reader directly
    let reader = try iPodDBReader(filePath: iTunesDBPath, fileType: .iTunesDB)

    // Build tracks using the internal buildTracks method pattern
    var unifiedTracks: [Track] = []
    if let iTunesDB = reader.iTunesDB {
        let playCounts = reader.playCountsDB

        let dummyURL = URL(fileURLWithPath: "/")
        for (index, itdbTrack) in iTunesDB.tracks.enumerated() {
            let playCountEntry = playCounts?.playCountEntry(for: index)
            let track = Track.from(itdbTrack, index: index, playCountEntry: playCountEntry, iPodURL: dummyURL)
            unifiedTracks.append(track)
        }
    }

    // Verify we have tracks
    #expect(!unifiedTracks.isEmpty, "Should have parsed tracks")

    // Test track properties
    let firstTrack = unifiedTracks[0]
    #expect(firstTrack.title != nil, "Track should have a title")
    #expect(firstTrack.duration > 0, "Track should have duration")

    print("✅ iPod façade test passed with \(unifiedTracks.count) tracks")
    print("✅ First track: \(firstTrack.title ?? "Unknown")")
}

@Test func testiPodPlaylistParsingWithITunesDB() async throws {
    // Get the test resources directory
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let iTunesDBPath = resourceURL.path

    // Create an iPod instance using the internal reader directly
    let reader = try iPodDBReader(filePath: iTunesDBPath, fileType: .iTunesDB)

    guard let iTunesDB = reader.iTunesDB else {
        Issue.record("Could not read iTunesDB")
        return
    }

    // Test playlist parsing
    let playlists = iTunesDB.playlists
    print("Found \(playlists.count) playlists")

    // There should be at least a master playlist
    #expect(!playlists.isEmpty, "Should have at least one playlist")

    // Check that playlists have been parsed correctly
    for playlist in playlists {
        print("Playlist: '\(playlist.name ?? "nil")' - \(playlist.trackIds.count) tracks, master: \(playlist.isMasterPlaylist)")

        // Master playlist should have tracks
        if playlist.isMasterPlaylist {
            #expect(playlist.trackIds.count > 0, "Master playlist should have tracks")
        }
    }

    // Build unified playlists using the same pattern as iPod
    var trackIdMap: [UInt32: UInt64] = [:]
    for itdbTrack in iTunesDB.tracks {
        trackIdMap[itdbTrack.uniqueId] = UInt64(itdbTrack.uniqueId)
    }

    for itdbPlaylist in playlists {
        let unifiedPlaylist = Playlist.from(itdbPlaylist)
        #expect(unifiedPlaylist.id > 0, "Playlist should have a valid ID")

        // Verify track IDs can be mapped
        let mappedTrackIds = itdbPlaylist.trackIds.compactMap { trackIdMap[$0] }
        print("Playlist '\(unifiedPlaylist.displayName)': \(mappedTrackIds.count)/\(itdbPlaylist.trackIds.count) tracks mapped")
    }

    print("✅ Playlist parsing test passed")
}

@Test func testiPodTrackFiltering() async throws {
    // Create some test tracks
    let tracks = [
        Track(
            id: 1, index: 0, title: "Song A", artist: "Artist 1", album: "Album X",
            genre: "Rock", composer: nil, comment: nil, grouping: nil,
            location: nil, duration: 180, fileSize: 0, bitrate: 0, sampleRate: 0,
            trackNumber: 0, totalTracks: 0, year: 0, playCount: 10, skipCount: 0,
            rating: 5, lastPlayed: Date(), lastSkipped: nil, bookmark: nil,
            dateAdded: nil, dateModified: nil
        ),
        Track(
            id: 2, index: 1, title: "Song B", artist: "Artist 2", album: "Album X",
            genre: "Pop", composer: nil, comment: nil, grouping: nil,
            location: nil, duration: 200, fileSize: 0, bitrate: 0, sampleRate: 0,
            trackNumber: 0, totalTracks: 0, year: 0, playCount: 5, skipCount: 0,
            rating: 3, lastPlayed: Date().addingTimeInterval(-3600), lastSkipped: nil, bookmark: nil,
            dateAdded: nil, dateModified: nil
        ),
        Track(
            id: 3, index: 2, title: "Song C", artist: "Artist 1", album: "Album Y",
            genre: "Rock", composer: nil, comment: nil, grouping: nil,
            location: nil, duration: 220, fileSize: 0, bitrate: 0, sampleRate: 0,
            trackNumber: 0, totalTracks: 0, year: 0, playCount: 0, skipCount: 0,
            rating: 0, lastPlayed: nil, lastSkipped: nil, bookmark: nil,
            dateAdded: nil, dateModified: nil
        )
    ]

    // Test filtering by artist
    let artist1Tracks = tracks.filter { $0.artist?.localizedCaseInsensitiveContains("Artist 1") == true }
    #expect(artist1Tracks.count == 2, "Should find 2 tracks by Artist 1")

    // Test filtering by album
    let albumXTracks = tracks.filter { $0.album?.localizedCaseInsensitiveContains("Album X") == true }
    #expect(albumXTracks.count == 2, "Should find 2 tracks from Album X")

    // Test filtering by genre
    let rockTracks = tracks.filter { $0.genre?.localizedCaseInsensitiveContains("Rock") == true }
    #expect(rockTracks.count == 2, "Should find 2 Rock tracks")

    // Test played tracks
    let playedTracks = tracks.filter { $0.playCount > 0 }
    #expect(playedTracks.count == 2, "Should find 2 played tracks")

    // Test never played tracks
    let neverPlayedTracks = tracks.filter { $0.playCount == 0 }
    #expect(neverPlayedTracks.count == 1, "Should find 1 never played track")

    // Test top rated
    let topRated = tracks.filter { $0.rating >= 4 }
    #expect(topRated.count == 1, "Should find 1 top-rated track")

    // Test search
    let searchResults = tracks.filter { track in
        track.title?.localizedCaseInsensitiveContains("Song") == true ||
        track.artist?.localizedCaseInsensitiveContains("Song") == true
    }
    #expect(searchResults.count == 3, "Should find all tracks with 'Song' in title")

    print("✅ Track filtering tests passed")
}

@Test func testiPodStatisticsCalculation() async throws {
    let tracks = [
        Track(
            id: 1, index: 0, title: "Song A", artist: nil, album: nil,
            genre: nil, composer: nil, comment: nil, grouping: nil,
            location: nil, duration: 180, fileSize: 1000000, bitrate: 0, sampleRate: 0,
            trackNumber: 0, totalTracks: 0, year: 0, playCount: 10, skipCount: 0,
            rating: 0, lastPlayed: nil, lastSkipped: nil, bookmark: nil,
            dateAdded: nil, dateModified: nil
        ),
        Track(
            id: 2, index: 1, title: "Song B", artist: nil, album: nil,
            genre: nil, composer: nil, comment: nil, grouping: nil,
            location: nil, duration: 200, fileSize: 2000000, bitrate: 0, sampleRate: 0,
            trackNumber: 0, totalTracks: 0, year: 0, playCount: 5, skipCount: 0,
            rating: 0, lastPlayed: nil, lastSkipped: nil, bookmark: nil,
            dateAdded: nil, dateModified: nil
        ),
        Track(
            id: 3, index: 2, title: "Song C", artist: nil, album: nil,
            genre: nil, composer: nil, comment: nil, grouping: nil,
            location: nil, duration: 220, fileSize: 3000000, bitrate: 0, sampleRate: 0,
            trackNumber: 0, totalTracks: 0, year: 0, playCount: 3, skipCount: 0,
            rating: 0, lastPlayed: nil, lastSkipped: nil, bookmark: nil,
            dateAdded: nil, dateModified: nil
        )
    ]

    // Calculate total play count
    let totalPlayCount: UInt64 = tracks.reduce(0) { $0 + UInt64($1.playCount) }
    #expect(totalPlayCount == 18, "Total play count should be 18")

    // Calculate total duration
    let totalDuration: TimeInterval = tracks.reduce(0) { $0 + $1.duration }
    #expect(totalDuration == 600, "Total duration should be 600 seconds")

    // Calculate total file size
    let totalSize: UInt64 = tracks.reduce(0) { $0 + $1.fileSize }
    #expect(totalSize == 6000000, "Total size should be 6MB")

    // Get unique values
    let artists: [String] = Array(Set(tracks.compactMap { $0.artist }))
    #expect(artists.isEmpty, "No artists in test tracks")

    print("✅ Statistics calculation tests passed")
}


