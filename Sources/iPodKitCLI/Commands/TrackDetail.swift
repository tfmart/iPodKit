//
//  TrackDetail.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import iPodKitCLICore

struct TrackDetail: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "track",
        abstract: "Show full details for a single track."
    )

    // Declared before the option group so the required ID is the first
    // positional; the optional path comes second: ipodkit track <id> [<path>]
    @Argument(help: "Track ID (see the tracks command).")
    var trackID: UInt64

    @OptionGroup var options: GlobalOptions

    func run() throws {
        let ipod = try options.loadiPod()
        let track = try findTrack(withID: trackID, in: ipod)

        if options.json {
            print(try JSONOutput.string(TrackDTO(track)))
        } else {
            print(OutputFormatter.trackDetail(track))
        }
    }
}
