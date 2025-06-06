# ``iPodKit``

A comprehensive Swift library for parsing iTunes database files from iPod devices.

## Overview

iPodKit provides complete support for parsing all major iPod database formats, from the standard iTunesDB files used by classic iPods to the specialized formats used by iPod Shuffle and iPod Photo models. With its protocol-based architecture and type-safe binary parsing, iPodKit makes it easy to extract track metadata, playlists, artwork, and playback statistics from any iPod database.

### Supported Devices and Formats

iPodKit supports database files from all major iPod models:

- **Standard iPods**: iTunesDB, Play Counts, On-The-Go Playlists, Equalizer Presets
- **iPod Photo**: Artwork Database, Photo Database  
- **iPod Shuffle**: iTunesSD, iTunesStats, iTunesShuffle, iTunesPState

### Key Features

- **Universal Parsing**: Support for 10+ different iTunes database file formats
- **Device Auto-Detection**: Automatically identifies iPod model and loads appropriate databases
- **Type-Safe Architecture**: Protocol-based binary parsing with comprehensive error handling
- **Rich Metadata Access**: Complete track information, artwork, ratings, play counts, and more
- **Search & Filter APIs**: Powerful methods for finding tracks, artists, albums, and playlists
- **Command-Line Tools**: Built-in analyzer for testing and debugging database files

## Getting Started

### Installation

Add iPodKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/iPodKit.git", from: "1.0.0")
]
```

### Quick Start

Parse an iTunes database file:

```swift
import iPodKit

// Parse a single iTunes database file
let reader = try iTunesDBReader(filePath: "/path/to/iTunesDB")
print("Found \(reader.trackCount) tracks")

// Parse entire iPod directory with auto-detection
let ipodReader = try iPodDBReader(iPodPath: "/Volumes/iPod")
print("Device Type: \(ipodReader.deviceType)")
```

## Topics

### Core Architecture

- <doc:BinaryParsingFramework>
- <doc:ProtocolBasedDesign>
- <doc:ErrorHandling>

### Database Formats

- <doc:StandardiPoddatabases>
- <doc:iPodShuffleFormats>
- <doc:ArtworkAndPhotoDatabase>

### Advanced Usage

- <doc:CustomParsers>
- <doc:PerformanceOptimization>
- <doc:DebuggingTechniques>

### API Reference

- ``iPodDBReader``
- ``iTunesDBReader``
- ``ITDBTrack``
- ``IPKParseable``
- ``IPKField``

## See Also

- [iTunes Database Format Specification](http://www.ipodlinux.org/ITunesDB/)
- [iPodLinux Project](http://www.ipodlinux.org/)