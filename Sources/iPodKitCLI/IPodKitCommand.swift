//
//  IPodKitCommand.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import iPodKitCLICore

@main
struct IPodKitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ipodkit",
        abstract: "Read tracks, playlists, and artwork from an iPod.",
        discussion: """
            Point any command at a mounted iPod volume, a directory containing \
            database files, or a database file itself. When no path is given, \
            a mounted iPod is auto-detected in /Volumes.

            Pass --json for machine-readable output: stdout carries only the \
            JSON document and all diagnostics go to stderr.
            """,
        version: CLIVersion.current,
        subcommands: [
            Info.self,
            Device.self,
            Tracks.self,
            TrackDetail.self,
            Playlists.self,
            ArtworkExport.self,
        ]
    )
}
