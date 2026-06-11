//
//  TrackFilterTests.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Testing
import iPodKitCLICore
@testable import iPodKit

private let sampleTracks = [
    makeTrack(id: 1, title: "Come Together", artist: "The Beatles", album: "Abbey Road"),
    makeTrack(id: 2, title: "Something", artist: "The Beatles", album: "Abbey Road"),
    makeTrack(id: 3, title: "Paranoid Android", artist: "Radiohead", album: "OK Computer"),
    makeTrack(id: 4, title: nil, artist: nil, album: nil),
]

@Test func testArtistFilterIsCaseInsensitiveSubstring() {
    let filter = TrackFilter(artist: "beatles")
    let result = filter.apply(to: sampleTracks)

    #expect(result.map(\.id) == [1, 2])
}

@Test func testSearchMatchesTitleArtistOrAlbum() {
    let filter = TrackFilter(search: "computer")
    let result = filter.apply(to: sampleTracks)

    #expect(result.map(\.id) == [3])
}

@Test func testSearchSkipsTracksWithNilFields() {
    let filter = TrackFilter(search: "anything")
    let result = filter.apply(to: sampleTracks)

    #expect(result.isEmpty)
}

@Test func testLimitAppliesAfterFiltering() {
    let filter = TrackFilter(artist: "The Beatles", limit: 1)
    let result = filter.apply(to: sampleTracks)

    #expect(result.map(\.id) == [1])
}

@Test func testEmptyFilterReturnsAllTracks() {
    let result = TrackFilter().apply(to: sampleTracks)

    #expect(result.count == sampleTracks.count)
}
