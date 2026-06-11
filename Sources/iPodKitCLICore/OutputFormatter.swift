//
//  OutputFormatter.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation
import iPodKit

/// Human-readable output formatting for the CLI.
package enum OutputFormatter {

    // MARK: - Duration

    /// Formats seconds as "M:SS" or "H:MM:SS".
    package static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Device Info

    package static func info(_ ipod: iPod) -> String {
        var lines: [String] = []
        lines.append("Device:    \(ipod.deviceName ?? "Unknown")")
        if let serial = ipod.serialNumber {
            lines.append("Serial:    \(serial)")
        }
        if let firmware = ipod.settings?.firmwareVersion {
            lines.append("Firmware:  \(firmware)")
        }
        if let source = ipod.syncSource, source.userName != nil || source.computerName != nil {
            let owner = [source.userName, source.computerName].compactMap { $0 }.joined(separator: " on ")
            lines.append("Synced:    \(owner)")
        }
        lines.append("Path:      \(ipod.url.path)")
        lines.append("Tracks:    \(ipod.tracks.count)")
        lines.append("Playlists: \(ipod.playlists.count)")
        let withArtwork = ipod.tracks.lazy.filter { $0.artwork != nil }.count
        lines.append("Artwork:   \(withArtwork) tracks with artwork")
        return lines.joined(separator: "\n")
    }

    // MARK: - Device Detail

    package static func deviceDetail(_ ipod: iPod) -> String {
        var lines: [String] = []

        func add(_ label: String, _ value: String?) {
            guard let value else { return }
            lines.append("\(label.padding(toLength: 18, withPad: " ", startingAt: 0))\(value)")
        }

        func onOff(_ value: Bool?) -> String? {
            value.map { $0 ? "on" : "off" }
        }

        add("Name:", ipod.deviceName)
        add("Serial:", ipod.serialNumber)
        add("Icon:", ipod.deviceIconURL?.path)
        if let source = ipod.syncSource, source.userName != nil || source.computerName != nil {
            add("Synced:", [source.userName, source.computerName].compactMap { $0 }.joined(separator: " on "))
        }

        if let settings = ipod.settings {
            lines.append("")
            lines.append("Settings")
            add("  Firmware:", settings.firmwareVersion)
            add("  Language:", settings.language)
            add("  Volume Limit:", settings.volumeLimit.map { "\($0)/255" })
            add("  Brightness:", settings.brightness.map { "\($0)%" })
            add("  24h Clock:", onOff(settings.usesTwentyFourHourClock))
            add("  Clicker:", onOff(settings.clickerEnabled))
            add("  Shuffle:", settings.shuffleMode?.rawValue)
            add("  Repeat:", settings.repeatMode?.rawValue)
            add("  Crossfade:", onOff(settings.crossfadeEnabled))
            add("  Sound Check:", onOff(settings.soundCheckEnabled))
            add("  VoiceOver:", onOff(settings.voiceOverEnabled))
        }

        for radio in ipod.radioPresets {
            lines.append("")
            lines.append("Radio (\(radio.region))")
            add("  Last Station:", radio.lastStation.map { String(format: "%.1f MHz", $0) })
            if !radio.presets.isEmpty {
                add("  Presets:", radio.presets.map { String(format: "%.1f", $0) }.joined(separator: ", ") + " MHz")
            }
        }

        if !ipod.bluetoothDevices.isEmpty {
            lines.append("")
            lines.append("Bluetooth")
            for device in ipod.bluetoothDevices {
                var services: [String] = []
                if device.supportsAudio { services.append("audio") }
                if device.supportsRemoteControl { services.append("remote") }
                let serviceList = services.isEmpty ? "" : "  (\(services.joined(separator: ", ")))"
                lines.append("  \(device.address)  \(device.name ?? "Unknown")\(serviceList)")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Track Table

    package static func tracksTable(_ tracks: [Track]) -> String {
        guard !tracks.isEmpty else { return "No tracks found." }

        let rows = tracks.map { track in
            [
                String(track.id),
                track.title ?? "-",
                track.artist ?? "-",
                track.album ?? "-",
                duration(track.duration),
                String(track.playCount),
            ]
        }

        let headers = ["ID", "TITLE", "ARTIST", "ALBUM", "DURATION", "PLAYS"]
        let caps = [20, 36, 24, 24, 8, 5]
        return table(headers: headers, rows: rows, caps: caps)
    }

    // MARK: - Track Detail

    package static func trackDetail(_ track: Track) -> String {
        var lines: [String] = []

        func add(_ label: String, _ value: String?) {
            guard let value else { return }
            lines.append("\(label.padding(toLength: 18, withPad: " ", startingAt: 0))\(value)")
        }

        add("ID:", String(track.id))
        add("Title:", track.title)
        add("Artist:", track.artist)
        add("Album:", track.album)
        add("Genre:", track.genre)
        add("Composer:", track.composer)
        add("Comment:", track.comment)
        add("Grouping:", track.grouping)
        add("Media Type:", track.mediaType.displayName)
        add("Duration:", duration(track.duration))
        add("File Size:", track.fileSize > 0 ? "\(track.fileSize) bytes" : nil)
        add("Bitrate:", track.bitrate.map { "\($0) kbps" })
        add("Sample Rate:", track.sampleRate.map { "\($0) Hz" })
        add("Track:", track.trackNumber.map { number in
            track.totalTracks.map { "\(number) of \($0)" } ?? String(number)
        })
        add("Disc:", track.discNumber.map { number in
            track.totalDiscs.map { "\(number) of \($0)" } ?? String(number)
        })
        add("Year:", track.year.map(String.init))
        add("BPM:", track.bpm.map(String.init))
        add("Compilation:", track.isCompilation ? "yes" : nil)
        add("Play Count:", String(track.playCount))
        add("Skip Count:", String(track.skipCount))
        add("Rating:", track.rating > 0 ? String(repeating: "★", count: track.rating) : nil)
        add("Last Played:", track.lastPlayed.map(formatDate))
        add("Last Skipped:", track.lastSkipped.map(formatDate))
        add("Date Added:", track.dateAdded.map(formatDate))
        add("Date Modified:", track.dateModified.map(formatDate))
        add("Bookmark:", track.bookmark.map(duration))
        add("Location:", track.location)
        add("Artwork:", track.artwork.map { artwork in
            artwork.sizes.map { "\($0.width)x\($0.height)" }.joined(separator: ", ")
        })

        return lines.joined(separator: "\n")
    }

    // MARK: - Playlists

    package static func playlistsList(_ playlists: [Playlist]) -> String {
        guard !playlists.isEmpty else { return "No playlists found." }

        let rows = playlists.map { playlist in
            var flags: [String] = []
            if playlist.isMasterPlaylist { flags.append("master") }
            if playlist.isPodcast { flags.append("podcast") }
            return [
                String(playlist.id),
                playlist.name,
                String(playlist.trackCount),
                flags.joined(separator: ", "),
            ]
        }

        let headers = ["ID", "NAME", "TRACKS", "FLAGS"]
        let caps = [20, 40, 6, 16]
        return table(headers: headers, rows: rows, caps: caps)
    }

    // MARK: - Helpers

    private static func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    private static func table(headers: [String], rows: [[String]], caps: [Int]) -> String {
        // Column width: longest cell, capped, never narrower than the header.
        var widths = headers.map(\.count)
        for row in rows {
            for (index, cell) in row.enumerated() {
                widths[index] = max(widths[index], min(cell.count, caps[index]))
            }
        }

        func line(_ cells: [String]) -> String {
            cells.enumerated().map { index, cell in
                let truncated = truncate(cell, to: widths[index])
                // Don't pad the last column to avoid trailing whitespace.
                if index == cells.count - 1 { return truncated }
                return truncated.padding(toLength: widths[index], withPad: " ", startingAt: 0)
            }
            .joined(separator: "  ")
        }

        var output = [line(headers)]
        output.append(contentsOf: rows.map(line))
        return output.joined(separator: "\n")
    }

    private static func truncate(_ string: String, to width: Int) -> String {
        guard string.count > width else { return string }
        return String(string.prefix(max(width - 1, 1))) + "…"
    }
}
