# Getting Started with iPodKit

Load an iPod database and read its tracks, playlists, and artwork.

## Overview

iPodKit reads iPod database files. Create an ``iPod`` from an iTunesDB,
iTunesSD, Library.itdb, or a directory that contains one of those files, then
use the loaded ``Track``, ``Playlist``, and ``Artwork`` values directly.

```swift
import iPodKit

let url = URL(fileURLWithPath: "/Users/me/iPod Database/iTunesDB")
let ipod = try iPod(contentsOf: url)

print(ipod.deviceName ?? "Unknown iPod")
print("\(ipod.tracks.count) tracks")
print("\(ipod.playlists.count) playlists")
```

If you pass a directory, iPodKit searches the known database locations inside
that directory. If you pass a database file, iPodKit reads that file directly
and uses nearby sidecar files when it can find them.

If you want to inspect the same data from a terminal first, use the
<doc:CommandLineTool>.

## Read Tracks

Use ``iPod/tracks`` to list every track in the loaded library.

```swift
for track in ipod.tracks {
    let title = track.title ?? "Unknown Title"
    let artist = track.artist ?? "Unknown Artist"

    print("\(title) by \(artist)")
}
```

Use optional binding for metadata that may be absent, and use ``Track/id`` for
stable identity when diffing or storing references.

## Read Playlists

Use ``iPod/playlists`` to inspect playlists. Each ``Playlist`` contains resolved
``Playlist/tracks`` in playlist order.

```swift
for playlist in ipod.playlists {
    print("\(playlist.name): \(playlist.tracks.count) tracks")

    for track in playlist.tracks {
        print(track.title ?? "Unknown Title")
    }
}
```

If the loaded database doesn't include playlist records, ``iPod/playlists`` is
empty.

## Load Artwork

Artwork metadata is part of the loaded snapshot, and image data is read when you
ask for it.

```swift
if let artwork = ipod.tracks.first?.artwork {
    let image = try await artwork.image()
    print("Loaded artwork: \(image.width)x\(image.height)")
}
```

Use ``Artwork/sizes`` and ``Artwork/image(size:)`` when you need a specific
thumbnail size.

## Read Device Information

When the database comes from a mounted iPod volume, device-level data is
available as well:

```swift
print(ipod.serialNumber ?? "Unknown serial")
print(ipod.settings?.firmwareVersion ?? "Unknown firmware")
print("Synced with \(ipod.syncSource?.computerName ?? "unknown computer")")

for device in ipod.bluetoothDevices {
    print("Paired: \(device.name ?? device.address)")
}
```

See ``DeviceSettings``, ``SyncSource``, ``RadioPresets``, and
``BluetoothDevice`` for everything that is surfaced.

## Handle Errors

iPodKit throws ``iPodError`` when database files cannot be found or parsed.

```swift
do {
    let ipod = try iPod(contentsOf: url)
    print("Loaded \(ipod.tracks.count) tracks")
} catch iPodError.noDatabaseFound {
    // Ask the user to choose an iPod database file.
} catch {
    print(error.localizedDescription)
}
```

## See Also

- <doc:CommandLineTool>
- ``iPod``
- ``Track``
- ``Playlist``
- ``Artwork``
- ``iPodError``
