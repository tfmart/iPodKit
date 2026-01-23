# ``iPodKit``

A Swift library for reading iPod databases.

## Overview

iPodKit provides access to data stored on iPod devices. It automatically detects the device type and loads available database files, merging data from multiple sources into `Track` and `Playlist` objects.

### Quick Start

```swift
import iPodKit

let ipod = try iPod(path: "/Volumes/iPod")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}

let recent = ipod.recentlyPlayed(limit: 25)
let results = ipod.search("Beatles")
```

### Supported Library Formats

- **iTunesDB** - Binary format used by most iPod models
- **iTunesSD** - Binary format used by iPod Shuffle
- **iTunes Library (SQLite)** - SQLite-based format
- **ArtworkDB** - Album artwork storage

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

### Device Information

- ``iPod/deviceType``
- ``iPod/path``

### Advanced Usage

- ``iPod/DatabaseAccess``
- ``iPod/Configuration``

### Internal Architecture

- <doc:BinaryParsingFramework>
- <doc:ProtocolBasedDesign>
- <doc:StandardiPoddatabases>

## See Also

- [iTunes Database Format Specification](http://www.ipodlinux.org/ITunesDB/)
- [iPodLinux Project](http://www.ipodlinux.org/)
