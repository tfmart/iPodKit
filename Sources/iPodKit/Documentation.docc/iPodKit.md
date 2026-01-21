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

### Supported Devices

- iPod Classic (all generations)
- iPod Mini
- iPod Nano (all generations)
- iPod Shuffle (all generations)
- iPod Photo

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

- ``iPod/DatabaseAccess``
- ``iPod/Configuration``

### Internal Architecture

- <doc:BinaryParsingFramework>
- <doc:ProtocolBasedDesign>
- <doc:StandardiPoddatabases>

## See Also

- [iTunes Database Format Specification](http://www.ipodlinux.org/ITunesDB/)
- [iPodLinux Project](http://www.ipodlinux.org/)
