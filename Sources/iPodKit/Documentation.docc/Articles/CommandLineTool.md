# Using the Command Line Tool

Inspect iPod databases from a terminal with `ipodkit`.

## Overview

iPodKit includes `ipodkit`, a command line tool built on the same parser as the
Swift library. Use it to inspect a mounted iPod, script exports, or quickly
check database contents before integrating the framework.

When no path is provided, `ipodkit` searches for a mounted iPod in `/Volumes`.
You can also pass a mounted iPod volume, a directory containing iPod database
files, or a database file directly.

```bash
ipodkit info
ipodkit info /Volumes/MyiPod
ipodkit info "/Volumes/MyiPod/iPod_Control/iTunes/iTunesDB"
```

## Install

Download the prebuilt universal macOS binary from the latest GitHub release:

```bash
curl -fsSL https://github.com/tfmart/iPodKit/releases/latest/download/ipodkit-macos-universal.tar.gz | tar -xz
sudo mv ipodkit /usr/local/bin/
```

Or build the executable product from source:

```bash
git clone https://github.com/tfmart/iPodKit.git
cd iPodKit
swift build -c release --product ipodkit
cp .build/release/ipodkit /usr/local/bin/
```

## Common Tasks

Show a summary of the detected iPod:

```bash
ipodkit info
```

Show device metadata, settings, sync source, radio presets, and Bluetooth
pairings:

```bash
ipodkit device /Volumes/MyiPod
```

List tracks and narrow the output with filters:

```bash
ipodkit tracks --artist "beatles" --limit 20
ipodkit tracks --search "love" --playlist 4600230050724520468
```

Show a single track by ID:

```bash
ipodkit track 13915076778449898231
```

List playlists:

```bash
ipodkit playlists
```

List artwork sizes or export artwork as a PNG:

```bash
ipodkit artwork 13915076778449898231 --list
ipodkit artwork 13915076778449898231 --size 200x200 --output cover.png
```

## Time Zones

Binary iPod databases store timestamps as device-local wall-clock time. If the
iPod's time zone differs from the current machine's time zone, pass the device
time zone explicitly.

```bash
ipodkit tracks --timezone America/Sao_Paulo
```

## JSON Output

Every command accepts `--json`. In JSON mode, standard output contains only the
JSON document, diagnostics go to standard error, and failures exit nonzero.

```bash
ipodkit tracks --search "beatles" --json | jq -r '.[].title'
ipodkit playlists --json | jq '.[] | {name, trackCount}'
ipodkit info --json
```

JSON output uses stable identifiers and values that are safe for scripting:

- Track and playlist `id` values are decimal strings because iPod IDs are
  64-bit values that can exceed JavaScript's safe integer range.
- Dates are ISO 8601 UTC strings.
- Durations are seconds.
- `mediaType` is a stable lowercase identifier such as `audio`, `podcast`, or
  `audiobook`.

## See Also

- <doc:CommandReference>
- <doc:GettingStarted>
