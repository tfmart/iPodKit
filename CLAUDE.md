# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iPodKit is a Swift Package Manager library for parsing iTunes database files from iPod devices. It follows a **simple, invisible, gradual** SDK design pattern inspired by RevenueCat.

See `ARCHITECTURE.md` for the full init flow, parsing pipeline, and internal type mapping.

## Build and Test Commands

```bash
# Build the entire project
swift build

# Run tests
swift test

# Run specific test target
swift test --filter iPodKitTests

# Build and run the analyzer tool
swift run analyze-itunes-db /path/to/iPod

# Generate documentation
swift package generate-documentation
```

## SDK Design Principles

iPodKit follows three core principles:

1. **Simple** - Single entry point (`iPod` class), minimal API surface
2. **Invisible** - Complexity hidden internally, sensible defaults
3. **Gradual** - Progressive disclosure for advanced use cases

## Core Architecture

### Public API Layer (`Public/`)

The primary public interface consists of:

- **`iPod`** - Main entry point, the facade that abstracts all complexity
- **`Track`** - Unified track model combining data from multiple sources
- **`Playlist`** - Unified playlist model
- **`Artwork`** - Album artwork with multiple size options
- **`MediaType`** - Track media type (audio, video, podcast, etc.)
- **`iPodError`** - Public error types for consumers

```swift
let ipod = try iPod(contentsOf: URL(fileURLWithPath: "/Users/me/iPod Database/iTunesDB"))

print(ipod.deviceName ?? "Unknown")
print("Tracks: \(ipod.tracks.count)")

for track in ipod.tracks {
    print("\(track.title ?? "Unknown") - \(track.artist ?? "Unknown")")
    if let artwork = track.artwork {
        let image = try await artwork.image()
    }
}
```

### Internal Implementation Layer (`Internal/`)

Internal classes handle the complexity (users don't see these):

- **`iPodDBReader`** - Orchestrates loading all database files
- **`iTunesDBReader`** - Parses iTunesDB format
- **`iTunesLibraryReader`** - Parses iTunes Library database files

### Error System

Two-tier error design:

- **`iPodError`** (public) - What consumers catch: `invalidPath`, `noDatabaseFound`, `artworkNotFound`, `artworkDecodingFailed`, `corruptedData`, `databaseError`
- **`IPKParsingError`** (internal) - What parsers throw: `invalidOffset`, `invalidString`, `invalidMagicNumber`, `insufficientData`, `fieldSizeMismatch`, `fileNotFound`, `databaseError`

### Database Parsers

Each database type has a dedicated parser:

**Standard iPod:**
- `iTunesDB`, `ITDBTrack`, `ITDBPlaylist` - Main database
- `PlayCounts` - Play history
- `OTGPlaylist` - On-the-go playlists
- `EqualizerPresets` - EQ settings
- `ArtworkDatabase` - Album art
- `PhotoDatabase` - Photos

**iPod Shuffle:**
- `iTunesSD` - Main database (big-endian)
- `iTunesStats` - Play history
- `iTunesShuffle` - Shuffle order
- `iTunesPState` - Playback state

**Device files (`Internal/Databases/Device/`, loaded by `DeviceFilesReader`):**
- `iTunesPrefsFile` - Sync source (library owner + computer name, `frpd` binary)
- `iPodSettingsFile` - On-device settings XML
- Radio presets and Bluetooth paired devices (plists under `iPod_Control/Device/`)
- `DeviceSerialResolver` - Hardware serial via IOKit + host iTunes device registry (macOS only)

### Binary Parsing Framework

Protocol-based architecture for type-safe binary parsing:

- **`IPKField`** - Defines field locations with type-safe reading
- **`IPKParseable`** - Protocol for Data-initializable objects
- **`Data+Extensions`** - Binary reading utilities

## Project Structure

```
Sources/iPodKit/
├── iPodKit.swift              # Module-level documentation
├── Documentation.docc/        # DocC articles
├── Public/
│   ├── iPod.swift             # Main facade (public API)
│   ├── Models/
│   │   ├── Track.swift        # Unified track model
│   │   ├── Playlist.swift     # Unified playlist model
│   │   ├── Artwork.swift      # Album artwork model
│   │   ├── MediaType.swift    # Track media type enum
│   │   ├── SyncSource.swift   # Last-synced iTunes library info
│   │   ├── DeviceSettings.swift # On-device settings
│   │   ├── RadioPresets.swift # FM radio presets per region
│   │   └── BluetoothDevice.swift # Paired Bluetooth devices
│   └── Errors/
│       └── iPodError.swift     # Public error types
└── Internal/
    ├── Core/
    │   ├── Protocols/         # IPKField, IPKParseable
    │   ├── Extensions/        # Data+Extensions
    │   ├── Errors/            # IPKParsingError (internal)
    │   └── ArtworkDecoder.swift
    ├── Databases/
    │   ├── Standard/          # iTunesDB, PlayCounts, ITDBTrack
    │   ├── Shuffle/           # iTunesSD, iTunesStats, etc.
    │   ├── Media/             # ArtworkDatabase, PhotoDatabase
    │   ├── Playlists/         # ITDBPlaylist, OTGPlaylist
    │   └── Device/            # iTunesPrefsFile, iPodSettingsFile
    ├── Models/
    │   └── EqualizerPresets.swift
    └── Readers/
        ├── iPodDBReader.swift
        ├── iTunesDBReader.swift
        ├── iTunesLibraryReader.swift
        ├── DeviceFilesReader.swift
        └── DeviceSerialResolver.swift
```

## Development Patterns

### Access Control Rules

- Everything in `Public/` is `public`
- Everything in `Internal/` is explicitly `internal` (never `public`)
- Use `@testable import iPodKit` in tests to access internal types

### Adding Features to Public API

1. Add methods to `iPod` class in `Public/iPod.swift`
2. Keep implementation details in `Internal/` classes
3. Use `Track` and `Playlist` unified models for return types
4. Throw `iPodError` from public API, `IPKParsingError` from internal code

### Adding New Database Support

1. Create parser in appropriate `Internal/Databases/` category
2. Conform to `IPKParseable` protocol
3. Define binary layout using `IPKField` structs
4. Add to `iPodDBReader` for automatic loading
5. Convert to public models via internal convenience initializers (e.g., `Track(_:index:iPodURL:)`)

### Binary Field Reading

```swift
extension ITDBTrack {
    struct UniqueId: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
}

self.uniqueId = try Self.UniqueId().readUInt32(from: data)
```

### Date Conversion

All timestamp conversion goes through `IPKTimestamp` (`Internal/Core/IPKTimestamp.swift`). Never hand-roll epoch arithmetic at call sites. The two storage formats are **not** anchored the same way:

- **Binary databases** (iTunesDB, Play Counts, iTunesStats, playlists): Mac epoch (1904), holding the device's **local wall-clock time**. Convert with `IPKTimestamp.date(fromMacTimestamp:in:)`, passing the device time zone (threaded from `iPod(contentsOf:timeZone:)`).
- **SQLite databases** (`iTunes Library.itlp`): Apple/Core Data epoch (2001), in **true UTC**. Convert with `IPKTimestamp.date(fromAppleTimestamp:)`.

This was verified empirically: the same play appears in `Play Counts` and `Dynamic.itdb` with values differing by exactly the device's UTC offset. Every public `Date` must represent the true absolute instant.

### Documentation Style

- **Public API**: ScrobbleKit-style DocC with `/// Parameters`, `/// Returns`, `/// Throws`, code examples. Focus on what the user gets, not internal implementation.
- **Internal code**: Brief `//` comments for design decisions. Use `// MARK:` sections.

## Technical Documentation

The `docs/itunesdb_docs/` directory contains reference documentation for the iPod database binary formats:

- **wikiPodLinux documentation** - Comprehensive specification of iTunesDB binary format including track items, playlists, data objects, and field offsets
- **iPod Linux RTXC manual** - Additional technical reference

Refer to these documents when implementing new field parsing or debugging binary format issues.

## Testing

Run tests with:

```bash
swift test
```

Use real iPod database files in `Tests/iPodKitTests/Resources/` for integration tests.

## Logging

Use `os.Logger` for diagnostic output:

```swift
import os

private let logger = Logger(subsystem: "com.iPodKit", category: "Parsing")
logger.debug("Parsed \(trackCount) tracks")
```

Never use `print()` statements in library code.

## Git Commit Guidelines

- **Do not auto-commit or push** - Only commit or push when explicitly requested
- Commit changes **gradually in logical batches** (e.g., one file or one feature per commit)
- Use **short descriptive messages only** - No long descriptions or bullet points
- **No co-author tags** - Do not add `Co-Authored-By` to commit messages
