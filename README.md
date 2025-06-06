# iPodKit

A comprehensive Swift library for parsing iTunes database files from iPod devices. iPodKit supports all major iPod models including standard iPods, iPod Shuffle, and iPod Photo, providing complete access to tracks, playlists, artwork, photos, and playback state.

## Features

### Supported Database Files

**Standard iPod Models:**
- **iTunesDB** - Main track and playlist database
- **Play Counts** - Play counts, ratings, and last played information
- **OTG Playlist File** - On-The-Go playlists created directly on iPod
- **Equalizer Presets** - Custom equalizer settings
- **ArtworkDB** - Album artwork metadata and image information
- **Photo Database** - User photos and photo albums

**iPod Shuffle Models:**
- **iTunesSD** - Shuffle main database (big-endian format)
- **iTunesStats** - Play count statistics for Shuffle
- **iTunesShuffle** - Shuffled track order sequence
- **iTunesPState** - Current playback state (volume, position, modes)

### Key Capabilities

- **Universal Parsing** - Supports all known iTunes database formats
- **Device Auto-Detection** - Automatically identifies iPod model and loads appropriate files
- **Rich Metadata** - Full access to track info, artwork, ratings, play counts
- **Search & Filter** - Comprehensive APIs for finding tracks and playlists
- **Type Safety** - Protocol-based binary parsing with proper error handling
- **Command Line Tools** - Built-in analyzer for testing and debugging

## Installation

### Swift Package Manager

Add iPodKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/iPodKit.git", from: "1.0.0")
]
```

### Xcode

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter the repository URL: `https://github.com/yourusername/iPodKit.git`
4. Click **Add Package**

## Quick Start

### Parsing an iTunes Database

```swift
import iPodKit

// Parse a single iTunesDB file
let reader = try iTunesDBReader(filePath: "/path/to/iTunesDB")

print("Found \(reader.trackCount) tracks")
print("Artists: \(reader.allArtists().count)")
print("Albums: \(reader.allAlbums().count)")

// Search for tracks
let rockTracks = reader.tracks(fromAlbum: "Dark Side of the Moon")
let stingTracks = reader.tracks(byArtist: "Sting")
```

### Universal iPod Database Reader

```swift
import iPodKit

// Parse entire iPod directory (auto-detects device type and loads all databases)
let ipodReader = try iPodDBReader(iPodPath: "/Volumes/iPod")

print("Device Type: \(ipodReader.deviceType)")
print("Loaded Files: \(ipodReader.loadedFiles)")

// Access different database types
if let artworkDB = ipodReader.artworkDB {
    print("Found \(artworkDB.images.count) artwork images")
}

if let playCountsDB = ipodReader.playCountsDB {
    let mostPlayed = playCountsDB.mostPlayedEntries(limit: 10)
    print("Top played tracks: \(mostPlayed)")
}
```

### Working with Track Data

```swift
for track in reader.tracks.prefix(5) {
    print("🎵 \(track.displayName)")
    print("   Artist: \(track.artist ?? "Unknown")")
    print("   Album: \(track.album ?? "Unknown")")
    print("   Duration: \(track.durationFormatted)")
    print("   Rating: \(track.starRating)/5 stars")
    print("   Play Count: \(track.playCount)")
    print("   Last Played: \(track.lastPlayedFormatted)")
    print("   File Size: \(track.fileSizeFormatted)")
}
```

### Artwork and Photos

```swift
// Access artwork database
if let artworkDB = ipodReader.artworkDB {
    for image in artworkDB.images.prefix(3) {
        print("🖼️ Image \(image.imageId)")
        print("   Size: \(image.imageWidth)×\(image.imageHeight)")
        print("   File Size: \(image.formattedSize)")
    }
}

// Access photo database  
if let photoDB = ipodReader.photoDB {
    for album in photoDB.albums {
        print("📁 \(album.displayName) - \(album.photoCount) photos")
    }
}
```

## Command Line Tools

iPodKit includes a powerful command-line analyzer:

```bash
# Build the analyzer
swift build

# Analyze an iTunesDB file
swift run analyze-itunes-db /path/to/iTunesDB

# Parse artwork database
swift run analyze-itunes-db --artwork /path/to/ArtworkDB

# Analyze entire iPod (auto-detects all database files)
swift run analyze-itunes-db --ipod /Volumes/iPod

# Debug mode for detailed parsing information
swift run analyze-itunes-db --debug /path/to/iTunesDB
```

## Architecture

iPodKit uses a protocol-based architecture for type-safe binary parsing:

- **IPKField** - Defines binary field locations with type-safe reading
- **IPKParseable** - Protocol for objects that can be parsed from Data
- **Unified Reader** - Device-agnostic interface with auto-detection
- **Error Handling** - Comprehensive error types with detailed context

### Binary Format Support

iPodKit handles the complexities of iTunes database formats:
- Little-endian and big-endian integer parsing
- UTF-16/UTF-8 string encoding with iTunes-specific cleanup
- Mac epoch (1904) to Unix epoch timestamp conversion
- Magic number validation and structure verification

## Examples

See the `Sources/iTunesDBAnalyzer` directory for complete examples of:
- Parsing all database file types
- Device type detection
- Comprehensive data analysis
- Error handling patterns

## Requirements

- Swift 6.0+
- Foundation framework

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [iPodLinux iTunes Database Documentation](http://www.ipodlinux.org/ITunesDB/)
- iTunes database format specifications and field definitions

## Acknowledgments

Built with reference to the extensive reverse engineering work by the iPodLinux community.