# iPodKit

A Swift library for reading iPod databases.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/tfmart/iPodKit.git", from: "0.1.0")
]
```

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
