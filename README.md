# iPodKit

A Swift library for reading iPod databases.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/tfmart/iPodKit.git", from: "0.1.0")
]
```

## Command Line Tool

iPodKit ships with `ipodkit`, a CLI for reading iPod data from the terminal — handy for quick inspection, scripting, and AI agents.

### Install

Download the prebuilt universal binary (requires macOS 12+):

```bash
curl -fsSL https://github.com/tfmart/iPodKit/releases/latest/download/ipodkit-macos-universal.tar.gz | tar -xz && sudo mv ipodkit /usr/local/bin/
```

> Downloading the archive with a browser instead of `curl` quarantines it; clear it with `xattr -d com.apple.quarantine ipodkit`.

Or build from source:

```bash
git clone https://github.com/tfmart/iPodKit.git && cd iPodKit
swift build -c release --product ipodkit
cp .build/release/ipodkit /usr/local/bin/
```

### Usage

When no path is given, `ipodkit` auto-detects a mounted iPod in `/Volumes`.

```bash
# Device summary
ipodkit info
ipodkit info /Volumes/MyiPod

# Device details: serial, settings, sync source, radio presets, Bluetooth pairings
ipodkit device

# List tracks, with filters
ipodkit tracks --artist "beatles" --limit 20
ipodkit tracks --search "love" --playlist 4600230050724520468

# Full details for one track
ipodkit track 13915076778449898231

# List playlists
ipodkit playlists

# Export artwork as PNG
ipodkit artwork 13915076778449898231 --list
ipodkit artwork 13915076778449898231 --size 200x200 --output cover.png

# Timestamps in binary iPod databases are device-local wall-clock time;
# pass the device's time zone if it differs from this machine's
ipodkit tracks --timezone America/Sao_Paulo
```

### JSON output for scripts and agents

Every command accepts `--json`. Stdout then carries only the JSON document; diagnostics go to stderr, and failures exit nonzero.

```bash
ipodkit tracks --search "beatles" --json | jq -r '.[].title'
ipodkit playlists --json | jq '.[] | {name, trackCount}'
ipodkit info --json
```

Schema notes:

- `id` fields are **decimal strings** — iPod track IDs are 64-bit values that exceed JavaScript's safe integer range
- Dates are ISO8601 UTC, durations are seconds
- `mediaType` is a stable lowercase identifier (`audio`, `podcast`, `audiobook`, …)

## Quick Start

```swift
import iPodKit

let ipod = try iPod(contentsOf: URL(fileURLWithPath: "/Users/me/iPod Database/iTunesDB"))

print(ipod.deviceName ?? "Unknown iPod")
print("Tracks: \(ipod.tracks.count)")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}
```

## Features

### Track Metadata

```swift
if let track = ipod.tracks.first {
    track.title           // String?
    track.artist          // String?
    track.album           // String?
    track.genre           // String?
    track.composer        // String?
    track.duration        // TimeInterval (seconds)
    track.fileSize        // Int (bytes)
    track.bitrate         // Int? (kbps)
    track.trackNumber     // Int?
    track.year            // Int?
    track.discNumber      // Int?
    track.bpm             // Int?
    track.isCompilation   // Bool
    track.mediaType       // MediaType
}
```

### Playback Data

```swift
if let track = ipod.tracks.first {
    track.playCount       // Int
    track.skipCount       // Int
    track.rating          // Int (0-5 stars)
    track.lastPlayed      // Date?
    track.lastSkipped     // Date?
    track.dateAdded       // Date?
    track.bookmark        // TimeInterval? (resume position)
}
```

### Playlists

```swift
for playlist in ipod.playlists {
    print("\(playlist.name) - \(playlist.tracks.count) tracks")

    for track in playlist.tracks {
        print("  \(track.title ?? "Unknown")")
    }

    // Track identifiers are available when needed
    print(playlist.trackIds)
}
```

### Album Artwork

```swift
if let artwork = ipod.tracks.first?.artwork {
    // Largest available size
    let image = try await artwork.image()

    // Specific size
    let thumb = try await artwork.image(size: .init(width: 56, height: 56))

    // Available sizes
    print(artwork.sizes)
}
```

### Device Info

```swift
ipod.deviceName       // String? — e.g., "John's iPod"
```

## Supported Formats

| Format | Description |
|--------|-------------|
| iTunesDB | Binary format used by iPod Classic, Mini, and Nano |
| iTunesSD | Binary format used by iPod Shuffle |
| iTunes Library (SQLite) | Used by newer iPod models |
| ArtworkDB | Album artwork storage |
| PlayCounts | Play history and statistics |

## Tested Devices

**iPod**
- 5th Generation (Video)

**iPod nano**
- 6th Generation
- 7th Generation

## Requirements

- Swift 6.0+
- macOS 10.15+
- iOS 13+

## License

MIT License
