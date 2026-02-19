# ``iPodKit``

A Swift library for reading iPod databases.

## Overview

iPodKit parses iTunes database files from mounted iPod devices and provides
a simple, unified interface for accessing track metadata, playlists, and artwork.
It automatically detects the device type and loads all available database files,
merging data from multiple sources into ``Track`` and ``Playlist`` objects.

### Quick Start

```swift
import iPodKit

let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))

print(ipod.deviceName ?? "Unknown iPod")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}
```

### Supported Formats

- **iTunesDB** — Binary format used by iPod Classic, Mini, and Nano
- **iTunesSD** — Binary format used by iPod Shuffle
- **iTunes Library (SQLite)** — Used by newer iPod models
- **ArtworkDB** — Album artwork storage (merged automatically)

## Topics

### Essentials

- ``iPod``
- ``Track``
- ``Playlist``

### Media

- ``Artwork``
- ``MediaType``
- ``iPodModel``

### Errors

- ``IPKError``

### Internal Architecture

- <doc:BinaryParsingFramework>
- <doc:ProtocolBasedDesign>
- <doc:StandardiPoddatabases>
