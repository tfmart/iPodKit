//
//  Playlists.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import iPodKitCLICore

struct Playlists: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List playlists."
    )

    @OptionGroup var options: GlobalOptions

    func run() throws {
        let ipod = try options.loadiPod()

        if options.json {
            print(try JSONOutput.string(ipod.playlists.map(PlaylistDTO.init)))
        } else {
            print(OutputFormatter.playlistsList(ipod.playlists))
        }
    }
}
