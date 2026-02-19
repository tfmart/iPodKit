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

let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))

print(ipod.deviceName ?? "Unknown iPod")
print("Tracks: \(ipod.tracks.count)")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}
```

## Features

### Track Metadata

```swift
let track = ipod.tracks.first!

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
```

### Playback Data

```swift
track.playCount       // Int
track.skipCount       // Int
track.rating          // Int (0-5 stars)
track.lastPlayed      // Date?
track.lastSkipped     // Date?
track.dateAdded       // Date?
track.bookmark        // TimeInterval? (resume position)
```

### Playlists

```swift
for playlist in ipod.playlists {
    print("\(playlist.displayName) - \(playlist.trackCount) tracks")
}

// Resolve track references
let playlistTracks = ipod.tracks.filter { playlist.trackIds.contains($0.id) }
```

### Album Artwork

```swift
if let artwork = track.artwork {
    // Largest available size
    let image = try artwork.loadImage()

    // Specific size
    let thumb = try artwork.loadImage(width: 56, height: 56)

    // Available sizes
    print(artwork.sizes) // [(width: 56, height: 56), (width: 140, height: 140)]
}
```

### Device Info

```swift
ipod.deviceName       // String? — e.g., "John's iPod"
ipod.deviceTimeZone   // TimeZone? — last synced timezone
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

## Requirements

- Swift 6.0+
- macOS 10.15+
- iOS 13+

## License

MIT License
