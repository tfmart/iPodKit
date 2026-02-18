#!/usr/bin/env swift

import Foundation
import iPodKit

guard CommandLine.arguments.count > 1 else {
    print("Usage: analyze-itunes-db /path/to/iPod")
    print("")
    print("Example:")
    print("  analyze-itunes-db /Volumes/iPod")
    exit(1)
}

let iPodPath = CommandLine.arguments[1]

guard FileManager.default.fileExists(atPath: iPodPath) else {
    print("Path not found: \(iPodPath)")
    print("")
    print("Try looking for iPod volumes with:")
    print("  ls /Volumes")
    exit(1)
}

print("Analyzing iPod at: \(iPodPath)")
print(String(repeating: "=", count: 50))

do {
    let ipod = try iPod(url: URL(fileURLWithPath: iPodPath))

    if let deviceName = ipod.deviceName {
        print("Device: \(deviceName)")
    }
    print("Tracks: \(ipod.tracks.count)")
    print("Playlists: \(ipod.playlists.count)")
    print("")

    if !ipod.playlists.isEmpty {
        print("Playlists:")
        for playlist in ipod.playlists {
            print("  \(playlist.name) (\(playlist.trackCount) tracks)")
        }
        print("")
    }

    let tracksWithArtwork = ipod.tracks.filter { $0.artwork != nil }
    print("Tracks with artwork: \(tracksWithArtwork.count)")

} catch {
    print("Error: \(error)")
    exit(1)
}
