# ``iPodKit``

A Swift library for reading iPod databases. Simple API, invisible complexity, gradual disclosure for power users.

## Overview

iPodKit provides a simple, unified API for accessing all data stored on an iPod device. It automatically detects the device type and loads all available database files, merging data from multiple sources into easy-to-use `Track` and `Playlist` objects.

### Quick Start

```swift
import iPodKit

// One line to read your iPod
let ipod = try iPod(path: "/Volumes/iPod")

// Access your music
for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}

// Get recently played tracks
let recent = ipod.recentlyPlayed(limit: 25)

// Search for tracks
let results = ipod.search("Beatles")
```

That's it. No configuration, no database types to understand, no file paths to manage.

### Supported Devices

iPodKit automatically detects and supports:

- **Standard iPods / iPod Classic**: All generations
- **iPod Shuffle**: All generations
- **iPod Photo / iPod with Color Display**
- **iPod Nano**: All generations

### Design Principles

iPodKit follows modern SDK design principles:

1. **Simple**: One entry point (`iPod`), sensible defaults
2. **Invisible**: Complexity hidden, just works
3. **Gradual**: Advanced features available when needed

## Topics

### Essentials

- ``iPod``
- ``Track``
- ``Playlist``

### Playback Information

- ``iPod/recentlyPlayed(limit:)``
- ``iPod/mostPlayed(limit:)``
- ``iPod/neverPlayed()``
- ``iPod/topRated(minimumRating:)``

### Search and Filtering

- ``iPod/search(_:)``
- ``iPod/tracks(byArtist:)``
- ``iPod/tracks(fromAlbum:)``
- ``iPod/tracks(inGenre:)``

### Advanced Usage

For power users who need direct database access:

- ``iPod/DatabaseAccess``
- ``iPod/Configuration``

### Internal Architecture

These articles explain the internal binary parsing framework:

- <doc:BinaryParsingFramework>
- <doc:ProtocolBasedDesign>
- <doc:StandardiPoddatabases>

## See Also

- [iTunes Database Format Specification](http://www.ipodlinux.org/ITunesDB/)
- [iPodLinux Project](http://www.ipodlinux.org/)
