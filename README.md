# iPodKit

A Swift library for reading iPod databases.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/tfmart/iPodKit.git", from: "2.0.0")
]
```

## Quick Start

```swift
import iPodKit

let ipod = try iPod(path: "/Volumes/iPod")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}
```

## Features

### Searching and Filtering

```swift
let beatles = ipod.search("Beatles")
let rockTracks = ipod.tracks(inGenre: "Rock")
let abbeyRoad = ipod.tracks(fromAlbum: "Abbey Road")
```

### Playback History

```swift
let recent = ipod.recentlyPlayed(limit: 25)
let favorites = ipod.mostPlayed(limit: 10)
let unplayed = ipod.neverPlayed()
let bestSongs = ipod.topRated(minimumRating: 4)
```

### Track Metadata

```swift
let track = ipod.tracks.first!

track.title
track.artist
track.album
track.duration
track.durationFormatted  // "3:45"

track.playCount
track.lastPlayed         // Date?
track.skipCount
track.rating             // 0-5 stars
```

### Library Statistics

```swift
print("Tracks: \(ipod.trackCount)")
print("Artists: \(ipod.artists.count)")
print("Total duration: \(ipod.totalDurationFormatted)")
print("Total size: \(ipod.totalSizeFormatted)")
```

## Supported Library Formats

| Format | Description |
|--------|-------------|
| iTunesDB | Binary format used by most iPods |
| iTunesSD | Binary format for iPod Shuffle |
| iTunes Library (SQLite) | SQLite-based format |
| ArtworkDB | Album artwork storage |

## Tested Devices

**iPod Classic**
- 5th Generation (Video)

**iPod Nano**
- 6th Generation

## Requirements

- Swift 6.0+
- macOS, iOS, tvOS, watchOS

## License

MIT License
