# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iPodKit is a Swift Package Manager library for parsing iTunes database files from iPod devices. It follows a **simple, invisible, gradual** SDK design pattern inspired by RevenueCat.

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
```

## SDK Design Principles

iPodKit follows three core principles:

1. **Simple** - Single entry point (`iPod` class), minimal API surface
2. **Invisible** - Complexity hidden internally, sensible defaults
3. **Gradual** - Progressive disclosure for advanced use cases

## Core Architecture

### Public API Layer (Façade)

The primary public interface consists of:

- **`iPod`** - Main entry point, the façade that abstracts all complexity
- **`Track`** - Unified track model combining data from multiple sources
- **`Playlist`** - Unified playlist model
- **`Artwork`** - Album artwork with multiple size options
- **`MediaType`** - Track media type (audio, video, podcast, etc.)
- **`iPodModel`** - iPod device model identification
- **`IPKError`** - Error types for parsing failures

```swift
// Initialize from URL
let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))

// Access device info
print(ipod.deviceName ?? "Unknown")
print("Tracks: \(ipod.tracks.count)")
print("Playlists: \(ipod.playlists.count)")

// Access track data
for track in ipod.tracks {
    print("\(track.title ?? "Unknown") - \(track.artist ?? "Unknown")")
    if let artwork = track.artwork {
        let image = try artwork.loadImage()
    }
}
```

### Internal Implementation Layer

Internal classes handle the complexity (users don't see these):

- **`iPodDBReader`** (internal) - Orchestrates loading all database files
- **`iTunesDBReader`** - Parses iTunesDB format (exposed via `databases.iTunesDB`)

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

### Binary Parsing Framework

Protocol-based architecture for type-safe binary parsing:

- **`IPKField`** - Defines field locations with type-safe reading
- **`IPKParseable`** - Protocol for Data-initializable objects
- **`Data+Extensions`** - Binary reading utilities

## Project Structure

```
Sources/iPodKit/
├── iPod.swift                 # Main façade (public API)
├── iPodKit.swift              # Library exports
├── Core/
│   ├── Protocols/             # IPKField, IPKObject, IPKParseable
│   ├── Extensions/            # Data+Extensions
│   ├── Errors/                # IPKError
│   └── Fields/                # Common field structures
├── Databases/
│   ├── Standard/              # iTunesDB, PlayCounts, ITDBTrack
│   ├── Shuffle/               # iTunesSD, iTunesStats, etc.
│   ├── Media/                 # ArtworkDatabase, PhotoDatabase
│   └── Playlists/             # ITDBPlaylist, OTGPlaylist
├── Models/
│   ├── Track.swift            # Unified track model
│   ├── Playlist.swift         # Unified playlist model
│   ├── Artwork.swift          # Album artwork model
│   ├── MediaType.swift        # Track media type enum
│   └── iPodModel.swift        # Device model identification
└── Readers/
    ├── iPodDBReader.swift     # Internal orchestrator
    ├── iTunesDBReader.swift   # iTunesDB parser
    └── iTunesLibraryReader.swift
```

## Development Patterns

### Adding Features to Public API

1. Add methods to `iPod` class in `iPod.swift`
2. Keep implementation details in internal classes
3. Use `Track` and `Playlist` unified models for return types

### Adding New Database Support

1. Create parser in appropriate `/Databases` category
2. Conform to `IPKParseable` protocol
3. Define binary layout using `IPKField` structs
4. Add to `iPodDBReader` for automatic loading
5. Expose via `iPod.DatabaseAccess` if needed

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

iTunes uses Mac epoch (1904). Convert to Unix:

```swift
let macEpochOffset: TimeInterval = 2082844800
let unixTimestamp = TimeInterval(timestamp) - macEpochOffset
return Date(timeIntervalSince1970: unixTimestamp)
```

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
