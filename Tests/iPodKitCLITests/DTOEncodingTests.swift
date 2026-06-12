//
//  DTOEncodingTests.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Testing
import Foundation
import iPodKitCLICore
@testable import iPodKit

@Test func testTrackDTOEncodesIdAsString() throws {
    // dbids exceed 2^53; the JSON schema uses decimal strings to survive
    // double-based JSON consumers.
    let track = makeTrack(id: 18_446_744_073_709_551_615, title: "Song")
    let json = try JSONOutput.string(TrackDTO(track))

    #expect(json.contains("\"id\" : \"18446744073709551615\""))
}

@Test func testTrackDTOEncodesDatesAsISO8601() throws {
    let track = makeTrack(lastPlayed: Date(timeIntervalSince1970: 0))
    let json = try JSONOutput.string(TrackDTO(track))

    #expect(json.contains("\"lastPlayed\" : \"1970-01-01T00:00:00Z\""))
}

@Test func testTrackDTOEncodesMediaTypeAsStableName() throws {
    let track = makeTrack(title: "Song")
    let json = try JSONOutput.string(TrackDTO(track))

    #expect(json.contains("\"mediaType\" : \"audio\""))
}

@Test func testTrackDTOOmitsNilArtwork() throws {
    let json = try JSONOutput.string(TrackDTO(makeTrack()))

    #expect(!json.contains("\"artwork\""))
}

@Test func testPlaylistDTOEncodesTrackIdsAsStrings() throws {
    let playlist = Playlist(
        id: 42,
        name: "Roadtrip",
        isMasterPlaylist: false,
        isPodcast: false,
        trackCount: 2,
        trackIds: [10, 18_446_744_073_709_551_615],
        timestamp: nil
    )
    let json = try JSONOutput.string(PlaylistDTO(playlist))

    #expect(json.contains("\"id\" : \"42\""))
    #expect(json.contains("\"18446744073709551615\""))
}

@Test func testDTOsFromRealDatabase() throws {
    let databaseURL = try #require(
        Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources")
    )
    let ipod = try iPod(
        contentsOf: databaseURL,
        configuration: iPod.Configuration(timeZone: TimeZone(identifier: "UTC")!)
    )

    #expect(!ipod.tracks.isEmpty)

    // Every track must round-trip through the DTO and encoder without throwing.
    let json = try JSONOutput.string(ipod.tracks.map(TrackDTO.init))
    #expect(json.hasPrefix("["))
}
