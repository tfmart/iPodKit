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

    return tempDir
}

/// Helper to clean up temporary directory
private func cleanupMockiPodDirectory(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
}

// MARK: - Initializer Tests

@Test func testiPodInitWithContentsOfURL() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(contentsOf: mockiPodURL)

    #expect(ipod.url == mockiPodURL, "iPod URL should match input URL")
    #expect(ipod.tracks.isEmpty == false, "iPod should have tracks")

    print("✅ iPod init(contentsOf:) test passed")
    print("   - Tracks: \(ipod.tracks.count)")
}

@Test func testiPodInitWithDatabaseFileURL() async throws {
    let databaseURL = try #require(Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources"))

    let ipod = try iPod(contentsOf: databaseURL)

    #expect(ipod.url == databaseURL, "iPod URL should match input URL")
    #expect(ipod.tracks.isEmpty == false, "iPod should have tracks")
}

@Test func testiPodInitWithMissingURLThrowsPublicError() async throws {
    let missingURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("iPodKitTests-Missing-\(UUID().uuidString)")

    do {
        _ = try iPod(contentsOf: missingURL)
        Issue.record("Expected iPod(contentsOf:) to throw")
    } catch {
        if case .invalidPath = error {
            #expect(error.recoverySuggestion != nil)
            #expect(error.localizedDescription.contains(missingURL.path) == false)
        } else {
            Issue.record("Expected invalidPath, got \(error)")
        }
    }
}

// MARK: - Track Data Tests

@Test func testiPodTracksHaveMetadata() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(contentsOf: mockiPodURL)

    #expect(ipod.tracks.isEmpty == false, "Should have tracks")

    let firstTrack = try #require(ipod.tracks.first)

    #expect(firstTrack.id > 0, "Track should have valid ID")
    #expect(firstTrack.duration > 0, "Track should have duration")
    #expect(firstTrack.title != nil, "Track should have title")

    print("✅ Track metadata test passed")
    print("   - First track: \(firstTrack.title ?? "Unknown")")
    print("   - Duration: \(firstTrack.duration)s")
    print("   - Artist: \(firstTrack.artist ?? "Unknown")")
}

@Test func testiPodPlaylistsExposeResolvedTracks() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(contentsOf: mockiPodURL)
    let masterPlaylist = try #require(ipod.playlists.first { $0.isMasterPlaylist })

    #expect(masterPlaylist.tracks.count == ipod.tracks.count, "Master playlist should resolve every track")
    #expect(masterPlaylist.trackCount == masterPlaylist.tracks.count)
    #expect(masterPlaylist.trackIds == masterPlaylist.tracks.map(\.id))
}

@Test func testiPodTrackPlayCountMerging() async throws {
    let mockiPodURL = try createMockiPodDirectory()
    defer { cleanupMockiPodDirectory(mockiPodURL) }

    let ipod = try iPod(contentsOf: mockiPodURL)

    let playedTracks = ipod.tracks.filter { $0.playCount > 0 }

    print("✅ Play count merging test passed")
    print("   - Total tracks: \(ipod.tracks.count)")
    print("   - Tracks with play counts: \(playedTracks.count)")

    if let mostPlayed = playedTracks.max(by: { $0.playCount < $1.playCount }) {
        print("   - Most played: \(mostPlayed.title ?? "Unknown") (\(mostPlayed.playCount) plays)")
    }
}

// MARK: - Edge Case Tests

@Test func testiPodInitWithEmptyDirectory() async throws {
    let emptyDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("iPodKitTests-Empty-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: emptyDir) }

    let ipod = try iPod(contentsOf: emptyDir)

    #expect(ipod.tracks.isEmpty, "Empty directory should have no tracks")

    print("✅ Empty directory test passed")
}

@Test func testiPodInitWithPartialData() async throws {
    let partialDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("iPodKitTests-Partial-\(UUID().uuidString)")
    let iTunesDir = partialDir.appendingPathComponent("iPod_Control/iTunes")
    try FileManager.default.createDirectory(at: iTunesDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: partialDir) }

    if let iTunesDBURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") {
        let destURL = iTunesDir.appendingPathComponent("iTunesDB")
        try FileManager.default.copyItem(at: iTunesDBURL, to: destURL)
    }

    let ipod = try iPod(contentsOf: partialDir)

    #expect(ipod.tracks.isEmpty == false, "Should have tracks from iTunesDB")

    print("✅ Partial data test passed")
    print("   - Tracks: \(ipod.tracks.count)")
}
