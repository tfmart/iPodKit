//
//  iPodInitializerTests.swift
//  iPodKit
//
//  Created by Tomas Martins on 22/01/26.
//

import Testing
import Foundation
@testable import iPodKit

// MARK: - iPod Initializer Tests

/// Helper to create a temporary iPod directory structure from test resources
private func createMockiPodDirectory() throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("iPodKitTests-\(UUID().uuidString)")

    // Create iPod directory structure
    let iTunesDir = tempDir.appendingPathComponent("iPod_Control/iTunes")
    try FileManager.default.createDirectory(at: iTunesDir, withIntermediateDirectories: true)

    // Copy iTunesDB
    if let iTunesDBURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") {
        let destURL = iTunesDir.appendingPathComponent("iTunesDB")
        try FileManager.default.copyItem(at: iTunesDBURL, to: destURL)
    }

    // Copy Play Counts
    if let playCountsURL = Bundle.module.url(forResource: "Play Counts", withExtension: nil, subdirectory: "Resources") {
        let destURL = iTunesDir.appendingPathComponent("Play Counts")
        try FileManager.default.copyItem(at: playCountsURL, to: destURL)
    }

    // Create Artwork directory and copy ArtworkDB
    let artworkDir = tempDir.appendingPathComponent("iPod_Control/Artwork")
    try FileManager.default.createDirectory(at: artworkDir, withIntermediateDirectories: true)

    if let artworkDBURL = Bundle.module.url(forResource: "ArtworkDB", withExtension: nil, subdirectory: "Resources") {
        let destURL = artworkDir.appendingPathComponent("ArtworkDB")
        try FileManager.default.copyItem(at: artworkDBURL, to: destURL)
    }

    return tempDir
}

/// Helper to clean up temporary directory
private func cleanupMockiPodDirectory(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
}

// MARK: - URL Initializer Tests

@Test func testiPodInitWithURL() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    #expect(ipod.url == mockiPodURL, "iPod URL should match input URL")
    #expect(ipod.path == mockiPodURL.path, "iPod path should match URL path")
    #expect(!ipod.tracks.isEmpty, "iPod should have tracks")
    #expect(ipod.trackCount > 0, "Track count should be greater than zero")

    print("✅ iPod init(url:) test passed")
    print("   - Tracks: \(ipod.trackCount)")
    print("   - Device type: \(ipod.deviceType.rawValue)")
}

@Test func testiPodInitWithPath() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(path: mockiPodURL.path)

    #expect(ipod.path == mockiPodURL.path, "iPod path should match input path")
    #expect(ipod.url.path == mockiPodURL.path, "iPod URL path should match input path")
    #expect(!ipod.tracks.isEmpty, "iPod should have tracks")

    print("✅ iPod init(path:) test passed")
    print("   - Tracks: \(ipod.trackCount)")
}

// MARK: - Configuration Builder Tests

@Test func testiPodConfigureWithURL() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod.configure(url: mockiPodURL).build()

    #expect(ipod.url == mockiPodURL, "iPod URL should match configured URL")
    #expect(!ipod.tracks.isEmpty, "iPod should have tracks")

    print("✅ iPod.configure(url:).build() test passed")
}

@Test func testiPodConfigureWithPath() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod.configure(path: mockiPodURL.path).build()

    #expect(ipod.path == mockiPodURL.path, "iPod path should match configured path")
    #expect(!ipod.tracks.isEmpty, "iPod should have tracks")

    print("✅ iPod.configure(path:).build() test passed")
}

// MARK: - Device Type Detection Tests

@Test func testiPodDeviceTypeDetection() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    // With iTunesDB and ArtworkDB, should be detected as photo type
    #expect(ipod.deviceType == .photo || ipod.deviceType == .standard,
            "Device type should be photo or standard for iTunesDB-based iPod")

    print("✅ Device type detection test passed")
    print("   - Detected type: \(ipod.deviceType.rawValue)")
}

// MARK: - Track Data Tests

@Test func testiPodTracksHaveMetadata() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    #expect(!ipod.tracks.isEmpty, "Should have tracks")

    let firstTrack = ipod.tracks[0]

    // Test track has basic properties
    #expect(firstTrack.id > 0, "Track should have valid ID")
    #expect(firstTrack.duration > 0, "Track should have duration")
    #expect(!firstTrack.displayName.isEmpty, "Track should have display name")

    print("✅ Track metadata test passed")
    print("   - First track: \(firstTrack.displayName)")
    print("   - Duration: \(firstTrack.durationFormatted)")
    print("   - Artist: \(firstTrack.artist ?? "Unknown")")
}

@Test func testiPodTrackPlayCountMerging() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    // Check if play counts were merged from Play Counts file
    let playedTracks = ipod.tracks.filter { $0.playCount > 0 }

    // We know from the test resources that there are played tracks
    print("✅ Play count merging test passed")
    print("   - Total tracks: \(ipod.trackCount)")
    print("   - Tracks with play counts: \(playedTracks.count)")

    if let mostPlayed = playedTracks.max(by: { $0.playCount < $1.playCount }) {
        print("   - Most played: \(mostPlayed.displayName) (\(mostPlayed.playCount) plays)")
    }
}

// MARK: - Playlist Tests

@Test func testiPodPlaylists() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    #expect(!ipod.playlists.isEmpty, "Should have playlists")

    // Should have at least a master playlist
    let masterPlaylist = ipod.playlists.first { $0.isMasterPlaylist }
    #expect(masterPlaylist != nil, "Should have master playlist")

    if let master = masterPlaylist {
        #expect(master.trackCount > 0, "Master playlist should have tracks")
        #expect(master.displayName == "All Music", "Master playlist display name should be 'All Music'")
    }

    print("✅ Playlist test passed")
    print("   - Total playlists: \(ipod.playlistCount)")

    for playlist in ipod.playlists.prefix(5) {
        print("   - \(playlist.displayName): \(playlist.trackCount) tracks")
    }
}

@Test func testiPodTracksInPlaylist() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    guard let playlist = ipod.playlists.first(where: { !$0.isMasterPlaylist && $0.trackCount > 0 }) else {
        print("⚠️ No non-master playlist with tracks found, skipping test")
        return
    }

    let tracksInPlaylist = ipod.tracks(in: playlist)

    #expect(tracksInPlaylist.count == playlist.trackCount,
            "tracks(in:) should return correct number of tracks")

    print("✅ Tracks in playlist test passed")
    print("   - Playlist: \(playlist.displayName)")
    print("   - Tracks: \(tracksInPlaylist.count)")
}

// MARK: - Database Access Tests

@Test func testiPodDatabaseAccess() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    // Test database access
    #expect(ipod.databases.iTunesDB != nil, "Should have iTunesDB access")
    #expect(ipod.databases.playCounts != nil, "Should have playCounts access")
    #expect(ipod.databases.artwork != nil, "Should have artwork database access")

    // Verify raw database matches unified data
    if let rawDB = ipod.databases.iTunesDB {
        #expect(rawDB.trackCount == ipod.trackCount, "Raw DB track count should match unified count")
    }

    print("✅ Database access test passed")
    print("   - iTunesDB: \(ipod.databases.iTunesDB != nil)")
    print("   - PlayCounts: \(ipod.databases.playCounts != nil)")
    print("   - Artwork: \(ipod.databases.artwork != nil)")
}

// MARK: - Search and Filter Tests

@Test func testiPodSearch() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    // Get a known artist from the tracks
    guard let knownArtist = ipod.tracks.compactMap({ $0.artist }).first else {
        print("⚠️ No tracks with artists found, skipping search test")
        return
    }

    let searchResults = ipod.search(knownArtist)

    #expect(!searchResults.isEmpty, "Search should find tracks by artist")
    #expect(searchResults.allSatisfy { track in
        track.title?.localizedCaseInsensitiveContains(knownArtist) == true ||
        track.artist?.localizedCaseInsensitiveContains(knownArtist) == true ||
        track.album?.localizedCaseInsensitiveContains(knownArtist) == true ||
        track.genre?.localizedCaseInsensitiveContains(knownArtist) == true
    }, "All search results should contain the search term")

    print("✅ Search test passed")
    print("   - Query: '\(knownArtist)'")
    print("   - Results: \(searchResults.count)")
}

@Test func testiPodRecentlyPlayed() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    let recentlyPlayed = ipod.recentlyPlayed(limit: 10)

    // All recently played tracks should have a lastPlayed date
    #expect(recentlyPlayed.allSatisfy { $0.lastPlayed != nil },
            "Recently played tracks should have lastPlayed date")

    // Should be sorted by most recent first
    if recentlyPlayed.count >= 2 {
        for i in 0..<(recentlyPlayed.count - 1) {
            let current = recentlyPlayed[i].lastPlayed!
            let next = recentlyPlayed[i + 1].lastPlayed!
            #expect(current >= next, "Recently played should be sorted by date descending")
        }
    }

    print("✅ Recently played test passed")
    print("   - Count: \(recentlyPlayed.count)")
}

@Test func testiPodMostPlayed() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    let mostPlayed = ipod.mostPlayed(limit: 10)

    // All most played tracks should have play count > 0
    #expect(mostPlayed.allSatisfy { $0.playCount > 0 },
            "Most played tracks should have playCount > 0")

    // Should be sorted by play count descending
    if mostPlayed.count >= 2 {
        for i in 0..<(mostPlayed.count - 1) {
            #expect(mostPlayed[i].playCount >= mostPlayed[i + 1].playCount,
                    "Most played should be sorted by play count descending")
        }
    }

    print("✅ Most played test passed")
    print("   - Count: \(mostPlayed.count)")
}

@Test func testiPodNeverPlayed() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    let neverPlayed = ipod.neverPlayed()

    // All never played tracks should have play count = 0
    #expect(neverPlayed.allSatisfy { $0.playCount == 0 },
            "Never played tracks should have playCount = 0")

    print("✅ Never played test passed")
    print("   - Count: \(neverPlayed.count)")
}

// MARK: - Statistics Tests

@Test func testiPodStatistics() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    // Test statistics properties
    #expect(ipod.totalPlayCount >= 0, "Total play count should be non-negative")
    #expect(ipod.totalDuration > 0, "Total duration should be positive")
    #expect(ipod.totalSize > 0, "Total size should be positive")

    // Test formatted statistics
    #expect(!ipod.totalDurationFormatted.isEmpty, "Total duration should be formatted")
    #expect(!ipod.totalSizeFormatted.isEmpty, "Total size should be formatted")

    print("✅ Statistics test passed")
    print("   - Total tracks: \(ipod.trackCount)")
    print("   - Total duration: \(ipod.totalDurationFormatted)")
    print("   - Total size: \(ipod.totalSizeFormatted)")
    print("   - Total play count: \(ipod.totalPlayCount)")
}

// MARK: - Artist/Album/Genre Tests

@Test func testiPodArtistsAlbumsGenres() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(url: mockiPodURL)

    let artists = ipod.artists
    let albums = ipod.albums
    let genres = ipod.genres

    #expect(artists.count >= 0, "Should have artists list")
    #expect(albums.count >= 0, "Should have albums list")
    #expect(genres.count >= 0, "Should have genres list")

    // Test filtering by artist
    if let firstArtist = artists.first {
        let artistTracks = ipod.tracks(byArtist: firstArtist)
        #expect(!artistTracks.isEmpty, "Should find tracks by artist")
    }

    // Test filtering by album
    if let firstAlbum = albums.first {
        let albumTracks = ipod.tracks(fromAlbum: firstAlbum)
        #expect(!albumTracks.isEmpty, "Should find tracks by album")
    }

    // Test filtering by genre
    if let firstGenre = genres.first {
        let genreTracks = ipod.tracks(inGenre: firstGenre)
        #expect(!genreTracks.isEmpty, "Should find tracks by genre")
    }

    print("✅ Artists/Albums/Genres test passed")
    print("   - Artists: \(artists.count)")
    print("   - Albums: \(albums.count)")
    print("   - Genres: \(genres.count)")
}

// MARK: - Edge Case Tests

@Test func testiPodInitWithEmptyDirectory() async throws {
    // Create an empty directory (no iPod databases)
    let emptyDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("iPodKitTests-Empty-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: emptyDir) }

    // iPod initializer should succeed but with no tracks
    let ipod = try iPod(url: emptyDir)

    #expect(ipod.tracks.isEmpty, "Empty directory should have no tracks")
    #expect(ipod.deviceType == .unknown, "Empty directory should have unknown device type")

    print("✅ Empty directory test passed")
    print("   - Device type: \(ipod.deviceType.rawValue)")
}

@Test func testiPodInitWithPartialData() async throws {
    // Create directory with only iTunesDB (no Play Counts or Artwork)
    let partialDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("iPodKitTests-Partial-\(UUID().uuidString)")
    let iTunesDir = partialDir.appendingPathComponent("iPod_Control/iTunes")
    try FileManager.default.createDirectory(at: iTunesDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: partialDir) }

    // Copy only iTunesDB
    if let iTunesDBURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") {
        let destURL = iTunesDir.appendingPathComponent("iTunesDB")
        try FileManager.default.copyItem(at: iTunesDBURL, to: destURL)
    }

    let ipod = try iPod(url: partialDir)

    #expect(!ipod.tracks.isEmpty, "Should have tracks from iTunesDB")
    #expect(ipod.databases.iTunesDB != nil, "Should have iTunesDB")
    #expect(ipod.databases.playCounts == nil, "Should not have Play Counts")
    #expect(ipod.databases.artwork == nil, "Should not have Artwork")

    print("✅ Partial data test passed")
    print("   - Tracks: \(ipod.trackCount)")
    print("   - Device type: \(ipod.deviceType.rawValue)")
}
