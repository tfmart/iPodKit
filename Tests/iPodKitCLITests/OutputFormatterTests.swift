//
//  OutputFormatterTests.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Testing
import iPodKitCLICore
@testable import iPodKit

@Test func testDurationFormatting() {
    #expect(OutputFormatter.duration(0) == "0:00")
    #expect(OutputFormatter.duration(59) == "0:59")
    #expect(OutputFormatter.duration(222) == "3:42")
    #expect(OutputFormatter.duration(3723) == "1:02:03")
}

@Test func testTracksTableContainsHeaderAndValues() {
    let tracks = [makeTrack(id: 7, title: "Karma Police", artist: "Radiohead", duration: 261, playCount: 12)]
    let table = OutputFormatter.tracksTable(tracks)
    let lines = table.split(separator: "\n")

    #expect(lines.count == 2)
    #expect(lines[0].contains("ID"))
    #expect(lines[0].contains("TITLE"))
    #expect(lines[1].contains("Karma Police"))
    #expect(lines[1].contains("4:21"))
    #expect(lines[1].contains("12"))
}

@Test func testTracksTableTruncatesLongValues() {
    let longTitle = String(repeating: "a", count: 100)
    let table = OutputFormatter.tracksTable([makeTrack(title: longTitle)])

    #expect(!table.contains(longTitle))
    #expect(table.contains("…"))
}

@Test func testEmptyTracksTable() {
    #expect(OutputFormatter.tracksTable([]) == "No tracks found.")
}

@Test func testTrackDetailSkipsMissingFields() {
    let detail = OutputFormatter.trackDetail(makeTrack(id: 9, title: "Song"))

    #expect(detail.contains("Title:"))
    #expect(!detail.contains("Artist:"))
    #expect(!detail.contains("Year:"))
}
