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
track.fileSize        // UInt64 (bytes)
track.bitrate         // UInt32 (kbps)
track.trackNumber     // UInt32
track.year            // UInt32
```

### Playback Data

```swift
track.playCount       // UInt32
track.skipCount       // UInt32
track.rating          // Int (0-5 stars)
track.lastPlayed      // Date?
track.lastSkipped     // Date?
track.dateAdded       // Date?
track.bookmark        // TimeInterval? (resume position)
```

### Playlists

```swift
for playlist in ipod.playlists {
    print("\(playlist.name) - \(playlist.trackCount) tracks")
    print("Track IDs: \(playlist.trackIds)")
}
```

### Album Artwork

```swift
if let artwork = track.artwork {
    let image = try artwork.loadImage()
}
```

## Supported Library Formats

| Format | Description |
|--------|-------------|
| iTunesDB | Binary format used by most iPods |
| iTunesSD | Binary format for iPod Shuffle |
| iTunes Library (SQLite) | SQLite-based format |
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
