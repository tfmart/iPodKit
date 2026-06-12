//
//  GlobalOptions.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import Foundation
import iPodKit
import iPodKitCLICore

/// Options shared by every subcommand.
struct GlobalOptions: ParsableArguments {

    @Argument(help: "Path to the iPod volume or database. Omit to auto-detect a mounted iPod.")
    var path: String?

    @Option(
        name: .customLong("timezone"),
        help: "Device time zone identifier (e.g. Europe/Lisbon). Defaults to the current time zone."
    )
    var timezone: String?

    @Flag(name: .customLong("json"), help: "Print machine-readable JSON to stdout.")
    var json = false
}

extension GlobalOptions {

    /// Loads the iPod from the resolved path with the resolved time zone.
    func loadiPod() throws -> iPod {
        let configuration = iPod.Configuration(timeZone: try resolveTimeZone())
        let url = try resolveURL()
        return try iPod(contentsOf: url, configuration: configuration)
    }

    private func resolveTimeZone() throws -> TimeZone {
        guard let timezone else { return .current }
        guard let resolved = TimeZone(identifier: timezone) else {
            throw ValidationError("Unknown time zone identifier '\(timezone)'.")
        }
        return resolved
    }

    private func resolveURL() throws -> URL {
        if let path {
            let expanded = NSString(string: path).expandingTildeInPath
            guard FileManager.default.fileExists(atPath: expanded) else {
                throw ValidationError("Path not found: \(expanded)")
            }
            return URL(fileURLWithPath: expanded)
        }

        let volumes = iPodLocator.detectVolumes()
        switch volumes.count {
        case 0:
            throw ValidationError("No mounted iPod found in /Volumes. Pass a path explicitly.")
        case 1:
            printToStderr("Using iPod at \(volumes[0].path)")
            return volumes[0]
        default:
            let candidates = volumes.map { "  \($0.path)" }.joined(separator: "\n")
            throw ValidationError("Multiple mounted iPods found, pass one explicitly:\n\(candidates)")
        }
    }
}
