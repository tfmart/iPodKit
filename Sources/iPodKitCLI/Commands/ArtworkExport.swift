//
//  ArtworkExport.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import Foundation
import iPodKit
import iPodKitCLICore

struct ArtworkExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "artwork",
        abstract: "Export a track's artwork as PNG, or list available sizes."
    )

    // Declared before the option group so the required ID is the first
    // positional; the optional path comes second: ipodkit artwork <id> [<path>]
    @Argument(help: "Track ID (see the tracks command).")
    var trackID: UInt64

    @OptionGroup var options: GlobalOptions

    @Option(name: .shortAndLong, help: "Output PNG path. Defaults to artwork-<track-id>.png.")
    var output: String?

    @Option(help: "Thumbnail size to export, e.g. 140x140. Defaults to the largest available.")
    var size: String?

    @Flag(help: "List available artwork sizes without exporting.")
    var list = false

    func run() async throws {
        let ipod = try options.loadiPod()
        let track = try findTrack(withID: trackID, in: ipod)

        guard let artwork = track.artwork else {
            throw CLIError("Track \(trackID) has no artwork.")
        }

        if list {
            try printSizes(of: artwork)
            return
        }

        let image = try await artwork.image(size: try requestedSize(from: artwork))

        let outputPath = output ?? "artwork-\(trackID).png"
        let outputURL = URL(fileURLWithPath: NSString(string: outputPath).expandingTildeInPath)
        try PNGWriter.write(image, to: outputURL)

        if options.json {
            let result = ArtworkExportDTO(path: outputURL.path, width: image.width, height: image.height)
            print(try JSONOutput.string(result))
        } else {
            print("Wrote \(image.width)x\(image.height) PNG to \(outputURL.path)")
        }
    }

    private func printSizes(of artwork: Artwork) throws {
        if options.json {
            print(try JSONOutput.string(ArtworkInfoDTO(artwork)))
        } else {
            print("Available sizes: \(formatted(artwork.sizes))")
        }
    }

    private func requestedSize(from artwork: Artwork) throws -> Artwork.Size? {
        guard let size else { return nil }

        guard let parsed = SizeParser.parse(size) else {
            throw ValidationError("Invalid size '\(size)'. Use the form WIDTHxHEIGHT, e.g. 140x140.")
        }
        guard artwork.sizes.contains(parsed) else {
            throw CLIError("No \(size) artwork for track \(trackID). Available sizes: \(formatted(artwork.sizes))")
        }
        return parsed
    }

    private func formatted(_ sizes: [Artwork.Size]) -> String {
        sizes.map { "\($0.width)x\($0.height)" }.joined(separator: ", ")
    }
}
