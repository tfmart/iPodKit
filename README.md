# iPodKit

A Swift library for reading iPod databases. Simple API, invisible complexity, gradual disclosure for power users.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/tomasmartins/iPodKit.git", from: "2.0.0")
]
```

## Quick Start

```swift
import iPodKit

// One line to read your iPod
let ipod = try iPod(path: "/Volumes/iPod")

// Access your music
for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}
```

That's it. No configuration, no database types to understand, no file paths to manage.

## Simple API

### Tracks

```swift
let ipod = try iPod(path: "/Volumes/iPod")

// All tracks
let tracks = ipod.tracks

// Search
let beatles = ipod.search("Beatles")

// Filter by artist, album, or genre
let rockTracks = ipod.tracks(inGenre: "Rock")
let abbeyRoad = ipod.tracks(fromAlbum: "Abbey Road")
```

### Playback History

```swift
// Recently played (with merged play count data)
let recent = ipod.recentlyPlayed(limit: 25)

// Most played
let favorites = ipod.mostPlayed(limit: 10)

// Never played
let unplayed = ipod.neverPlayed()

// Top rated
let bestSongs = ipod.topRated(minimumRating: 4)
```

### Statistics

```swift
print("Tracks: \(ipod.trackCount)")
print("Artists: \(ipod.artists.count)")
print("Total duration: \(ipod.totalDurationFormatted)")
print("Total size: \(ipod.totalSizeFormatted)")
```

## Invisible Complexity

iPodKit automatically:

- Detects device type (standard iPod, Shuffle, Photo, SQLite-based)
- Loads all available database files
- Merges play count data with track metadata
- Handles encoding differences (UTF-8, UTF-16, big-endian, little-endian)
- Converts Mac epoch timestamps to standard `Date` objects

You don't need to know any of this. It just works.

## Progressive Disclosure

Need more control? Use the configuration builder:

```swift
let ipod = try iPod.configure(path: "/Volumes/iPod")
    .loadArtwork(true)
    .loadPhotos(true)
    .loadEqualizer(true)
    .build()
```

Need raw database access? It's available:

```swift
// Access underlying databases for advanced use cases
if let artworkDB = ipod.databases.artwork {
    for image in artworkDB.images {
        print("Image: \(image.imageWidth)x\(image.imageHeight)")
    }
}

if let playCounts = ipod.databases.playCounts {
    let mostPlayed = playCounts.mostPlayedEntries(limit: 10)
}
```

## Unified Track Model

The `Track` type combines data from multiple sources automatically:

```swift
let track = ipod.tracks.first!

// Metadata from iTunesDB
track.title
track.artist
track.album
track.duration
track.durationFormatted  // "3:45"

// Play data merged from Play Counts file
track.playCount
track.lastPlayed         // Date?
track.lastPlayedFormatted // "Jan 15, 2025, 3:45 PM"
track.skipCount
track.rating             // 0-5 stars
track.bookmark           // Resume position

// Computed properties
track.displayName        // Title or filename
track.hasBeenPlayed
track.playToSkipRatio
```

## Supported Devices

| Device Type | Database Format | Supported |
|-------------|-----------------|-----------|
| iPod Classic | iTunesDB | Yes |
| iPod Mini | iTunesDB | Yes |
| iPod Nano | iTunesDB / SQLite | Yes |
| iPod Shuffle | iTunesSD | Yes |
| iPod Photo | iTunesDB + ArtworkDB | Yes |
| iPod Touch | SQLite | Yes |

## Supported Files

**Standard iPods:**
- iTunesDB (tracks, playlists)
- Play Counts (play history)
- OTG Playlist (on-the-go playlists)
- Equalizer Presets
- ArtworkDB (album artwork)
- Photo Database

**iPod Shuffle:**
- iTunesSD (tracks)
- iTunesStats (play history)
- iTunesShuffle (shuffle order)
- iTunesPState (playback state)

## Command Line Tool

```bash
# Build
swift build

# Analyze an iPod
swift run analyze-itunes-db --ipod /Volumes/iPod

# Analyze a single database file
swift run analyze-itunes-db /path/to/iTunesDB

# Analyze artwork
swift run analyze-itunes-db --artwork /path/to/ArtworkDB
```

## Requirements

- Swift 6.0+
- macOS, iOS, tvOS, watchOS

## Design Principles

iPodKit follows modern SDK design principles:

1. **Simple** - One entry point (`iPod`), sensible defaults
2. **Invisible** - Complexity hidden, just works
3. **Gradual** - Advanced features available when needed

Inspired by [RevenueCat's SDK design](https://blog.jacobstechtavern.com/p/revenuecat-sdk).

## License

MIT License
