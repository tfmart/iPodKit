//
//  Tracks.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import iPodKitCLICore

struct Tracks: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List tracks, optionally filtered."
    )

    @OptionGroup var options: GlobalOptions

    @Option(help: "Filter by artist (case-insensitive substring match).")
    var artist: String?

    @Option(help: "Filter by album (case-insensitive substring match).")
    var album: String?

    @Option(help: "Filter by genre (case-insensitive substring match).")
    var genre: String?

    @Option(help: "Match against title, artist, or album.")
    var search: String?

    @Option(help: "Only list tracks from the playlist with this ID.")
    var playlist: UInt64?

    @Option(help: "Maximum number of tracks to print (applied after filtering).")
    var limit: Int?

    func validate() throws {
        if let limit, limit < 1 {
            throw ValidationError("--limit must be at least 1.")
        }
    }

    func run() throws {
        let ipod = try options.loadiPod()

        var tracks = ipod.tracks
        if let playlistID = playlist {
            guard let match = ipod.playlists.first(where: { $0.id == playlistID }) else {
                throw CLIError("No playlist with ID \(playlistID). Use the playlists command to list IDs.")
            }
            tracks = match.tracks
        }

        let filter = TrackFilter(artist: artist, album: album, genre: genre, search: search, limit: limit)
        let filtered = filter.apply(to: tracks)

        if options.json {
            print(try JSONOutput.string(filtered.map(TrackDTO.init)))
        } else {
            print(OutputFormatter.tracksTable(filtered))
        }
    }
}
