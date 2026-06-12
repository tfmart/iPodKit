# iPodKit

iPodKit is a Swift library and command line tool for reading iPod databases from classic iPod devices. It loads tracks, playlists, artwork, playback history, and device metadata from iTunesDB, iTunesSD, SQLite library, and artwork database files.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/tfmart/iPodKit.git", from: "0.1.0")
]
```

## Quick Start

Create an `iPod` from a mounted iPod volume, a directory containing iPod database files, or a database file directly.

```swift
import iPodKit

let url = URL(fileURLWithPath: "/Volumes/MyiPod")
let ipod = try iPod(contentsOf: url)

print(ipod.deviceName ?? "Unknown iPod")
print("\(ipod.tracks.count) tracks")
print("\(ipod.playlists.count) playlists")

for track in ipod.tracks {
    let title = track.title ?? "Unknown Title"
    let artist = track.artist ?? "Unknown Artist"

    print("\(title) by \(artist)")
}
```

Read the full [Quick Start](https://tfmart.github.io/iPodKit/documentation/ipodkit/gettingstarted/) guide for playlists, artwork, and device metadata.

## Command Line Tool

iPodKit also ships with `ipodkit`, a CLI for inspecting iPod data from the terminal. Install with:

```bash
curl -fsSL https://github.com/tfmart/iPodKit/releases/latest/download/ipodkit-macos-universal.tar.gz | tar -xz
sudo mv ipodkit /usr/local/bin/
```

When no path is given, `ipodkit` auto-detects a mounted iPod in `/Volumes`.

```bash
ipodkit tracks --artist "beatles" --limit 20
```

See the [Command Line Tool](https://tfmart.github.io/iPodKit/documentation/ipodkit/commandlinetool/) guide for install options, command examples, JSON output, and the full command reference.

## What iPodKit Reads

- Track metadata: title, artist, album, genre, duration, bitrate, track numbers, media type, and file location
- Playback data: play count, skip count, rating, last played, last skipped, date added, and bookmark position
- Playlists: playlist names, stable identifiers, ordered tracks, and track IDs
- Artwork: available thumbnail sizes and lazy image loading
- Device metadata: device name, serial number, icon, sync source, settings, radio presets, and Bluetooth pairings

## Examples

### Playlists

```swift
for playlist in ipod.playlists {
    print("\(playlist.name): \(playlist.tracks.count) tracks")

    for track in playlist.tracks {
        print(track.title ?? "Unknown Title")
    }
}
```

### Album Artwork

```swift
if let artwork = ipod.tracks.first?.artwork {
    let image = try await artwork.image()
    print("Loaded artwork: \(image.width)x\(image.height)")

    let thumbnail = try await artwork.image(size: .init(width: 56, height: 56))
    print("Loaded thumbnail: \(thumbnail.width)x\(thumbnail.height)")
}
```

### Device Info

```swift
print(ipod.serialNumber ?? "Unknown serial")
print(ipod.settings?.firmwareVersion ?? "Unknown firmware")
print("Synced with \(ipod.syncSource?.computerName ?? "unknown computer")")

for device in ipod.bluetoothDevices {
    print("Paired: \(device.name ?? device.address)")
}
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

iPodKit is available under the MIT License. See [LICENSE](LICENSE) for details.
