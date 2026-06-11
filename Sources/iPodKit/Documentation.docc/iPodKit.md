# ``iPodKit``

Read tracks, playlists, playback metadata, and artwork from iPod databases.

## Overview

iPodKit gives apps a Swift interface for iPod libraries. Load an ``iPod`` from
an iTunesDB, iTunesSD, Library.itdb, or a directory that contains one of those
files, then inspect ``Track``, ``Playlist``, and ``Artwork`` values.

### Quick Start

```swift
import iPodKit

let ipod = try iPod(contentsOf: URL(fileURLWithPath: "/Users/me/iPod Database/iTunesDB"))

print(ipod.deviceName ?? "Unknown iPod")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
}

for playlist in ipod.playlists {
    print("\(playlist.name): \(playlist.tracks.count) tracks")
}
```

### Supported Data

iPodKit automatically reads the supported database layout and merges sidecar
data when available:

- track metadata
- playlists
- play counts, ratings, skips, and last-played dates
- album artwork metadata and image data
- device information: serial number, settings, sync source, and device icon
- FM radio presets and paired Bluetooth devices

## Topics

### Getting Started

- <doc:GettingStarted>

### Essentials

- ``iPod``
- ``iPod/Configuration``
- ``Track``
- ``Playlist``

### Media

- ``Artwork``
- ``MediaType``

### Device Information

- ``SyncSource``
- ``DeviceSettings``
- ``RadioPresets``
- ``BluetoothDevice``

### Errors

- ``iPodError``
