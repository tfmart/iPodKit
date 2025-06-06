# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iPodKit is a Swift Package Manager library for parsing iTunes database files from iPod devices. It supports all major iPod database formats including standard iPods, iPod Shuffle, and iPod Photo models with comprehensive parsing capabilities for tracks, playlists, artwork, photos, and playback state.

## Build and Test Commands

```bash
# Build the entire project
swift build

# Run tests
swift test

# Run specific test target
swift test --filter iPodKitTests

# Build and run the analyzer tool
swift run analyze-itunes-db [options] /path/to/file

# Analyzer options:
# --debug      Debug mode for iTunesDB parsing
# --detailed   Detailed debug information
# --structure  Structure analysis
# --artwork    Parse ArtworkDB files
# --ipod       Parse entire iPod directory (auto-detects all database files)
```

## Core Architecture

### Binary Parsing Framework

The library uses a protocol-based architecture for parsing binary iTunes database formats:

- **IPKField**: Defines binary field locations (offset, length) with type-safe reading methods
- **IPKObject**: Base protocol for database objects with magic number validation
- **IPKParseable**: Protocol for objects that can be initialized from Data
- **Data+Extensions**: Little-endian and big-endian binary reading utilities

### Database File Types

iPodKit supports parsing 10+ different iTunes database file types:

**Standard iPod Files:**
- iTunesDB (main database) → `iTunesDBReader`
- Play Counts → `PlayCounts`
- OTG Playlist File → `OTGPlaylist`
- Equalizer Presets → `EqualizerPresets`
- ArtworkDB → `ArtworkDatabase`
- Photo Database → `PhotoDatabase`

**iPod Shuffle Files:**
- iTunesSD (big-endian main database) → `iTunesSD`
- iTunesStats → `iTunesStats`
- iTunesShuffle → `iTunesShuffle`
- iTunesPState → `iTunesPState`

### Unified Database Reader

`iPodDBReader` provides device-agnostic database access:
- Auto-detects iPod device type (standard/shuffle/photo)
- Loads all available database files from iPod directory structure
- Provides unified API for searching across all database types
- Handles file path resolution and optional file loading

### Field Definition Pattern

Each database structure defines its binary layout using nested IPKField structs:

```swift
extension ITDBTrack {
    struct UniqueId: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    // ... more fields
}
```

### String Parsing

iTunes databases use complex string encoding with artifacts. The `readMHODString` method in Data+Extensions handles:
- UTF-16/UTF-8 encoding detection
- Removal of iTunes-specific padding characters
- String cleanup and trimming

### Error Handling

`IPKError` enum provides structured error handling for:
- Invalid magic numbers with expected vs found values
- Insufficient data conditions
- Field size mismatches with specific field context
- String decoding failures

## Project Structure

The codebase is organized into logical modules for maintainability:

```
Sources/iPodKit/
├── iPodKit.swift              # Main library entry point
├── Core/                      # Core framework components
│   ├── Protocols/             # IPKField, IPKObject, IPKParseable
│   ├── Extensions/            # Data+Extensions for binary parsing
│   ├── Errors/                # IPKError definitions
│   └── Fields/                # Common field structures
├── Databases/                 # Database parsers by category
│   ├── Standard/              # iTunesDB, PlayCounts, ITDBTrack, etc.
│   ├── Shuffle/               # iTunesSD, iTunesStats, iTunesShuffle, etc.
│   ├── Media/                 # ArtworkDatabase, PhotoDatabase
│   └── Playlists/             # ITDBPlaylist, OTGPlaylist, etc.
├── Models/                    # Supporting data models
├── Readers/                   # High-level reader classes
│   ├── iTunesDBReader.swift   # Standard iTunes database reader
│   └── iPodDBReader.swift     # Unified multi-format reader
```

## Development Patterns

### Adding New Database File Support

1. Create parser struct in appropriate `/Databases` category
2. Conform to `IPKParseable` protocol
3. Define binary field layout using `IPKField` structs
4. Implement `init(from data: Data)` with magic number validation
5. Add convenience properties for data formatting and conversion
6. Add to `iPodDBReader` unified interface in `/Readers`
7. Update analyzer with new file type support

### Binary Field Reading

Always use IPKField protocol methods for type-safe reading:
```swift
self.uniqueId = try Self.UniqueId().readUInt32(from: data)
```

### Magic Number Validation

Use the standard validation pattern:
```swift
try Self.validateMagicNumber(from: data, expectedId: "mhit")
```

### Date Conversion

iTunes databases use Mac epoch (1904) timestamps. Convert to Unix epoch:
```swift
let macEpochOffset: TimeInterval = 2082844800
let unixTimestamp = TimeInterval(timestamp) - macEpochOffset
return Date(timeIntervalSince1970: unixTimestamp)
```

## Testing Database Files

Use the analyzer tool to validate parsing of new database files:
```bash
swift run analyze-itunes-db --artwork /path/to/ArtworkDB
swift run analyze-itunes-db --ipod /path/to/iPod/root
```

The analyzer provides detailed output showing successful parsing, file structure, and data validation.