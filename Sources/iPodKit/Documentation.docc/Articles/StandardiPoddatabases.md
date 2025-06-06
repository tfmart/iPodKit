# Standard iPod Databases

Deep dive into the binary formats used by classic iPod models.

## Overview

Standard iPod models (including iPod Classic, iPod Video, and iPod Mini) use a hierarchical database format centered around the iTunesDB file. This format stores track metadata, playlists, and usage statistics in a complex but well-structured binary format.

## Database Hierarchy

The iTunes database follows a hierarchical structure:

```
iTunesDB (mhbd)
├── Database Header
├── Track List Dataset (mhsd type 1)
│   └── Track List (mhlt)
│       ├── Track Item (mhit) #1
│       ├── Track Item (mhit) #2
│       └── ...
└── Playlist List Dataset (mhsd type 2)
    └── Playlist List (mhlp)
        ├── Playlist (mhyp) #1
        ├── Playlist (mhyp) #2
        └── ...
```

## Main Database: iTunesDB

The ``iTunesDB`` structure represents the main database header:

```swift
public struct iTunesDB: IPKParseable {
    let id: String = "mhbd"
    
    public let headerLength: UInt32        // Header size in bytes
    public let totalLength: UInt32         // Total file size
    public let versionNumber: UInt32       // Database version
    public let numberOfChildren: UInt32    // Number of datasets
}
```

### Magic Numbers and Identifiers

Every structure in the iTunes database begins with a 4-character magic number:

- `mhbd`: Database header (Music Header Database)
- `mhsd`: Dataset header (Music Header Set Data)
- `mhlt`: Track list (Music Header List Tracks)
- `mhit`: Track item (Music Header Item Track)
- `mhlp`: Playlist list (Music Header List Playlists)
- `mhyp`: Playlist (Music Header Playlist)

## Track Records: ITDBTrack

The ``ITDBTrack`` structure contains comprehensive metadata for each track:

```swift
public struct ITDBTrack: IPKParseable {
    // Binary metadata
    public let uniqueId: UInt32
    public let size: UInt32              // File size in bytes
    public let length: UInt32            // Duration in milliseconds
    public let trackNumber: UInt32
    public let year: UInt32
    public let bitrate: UInt32
    public let sampleRate: UInt32
    public let rating: UInt8             // Star rating (0-100)
    public let playCount: UInt32
    public let lastPlayed: UInt32        // Mac epoch timestamp
    
    // String metadata (parsed from mhod objects)
    public let title: String?
    public let artist: String?
    public let album: String?
    public let genre: String?
    public let location: String?         // File path
}
```

### Field Layout

Track records use a fixed-size header followed by variable-length string data:

```
Offset | Length | Field
-------|--------|-------
0      | 4      | Magic number ("mhit")
4      | 4      | Header length
8      | 4      | Total length
12     | 4      | Number of strings
16     | 4      | Unique ID
20     | 4      | Visible flag
...    | ...    | Additional fields
Header | Var    | String data objects (mhod)
```

### String Data Objects

String metadata is stored in separate mhod (Music Header Object Data) structures:

```swift
public struct ITDBDataObject: IPKParseable {
    public enum TypeIdentifier: UInt32 {
        case title = 1
        case location = 2
        case album = 3
        case artist = 4
        case genre = 5
        case filetype = 6
        case comment = 8
        case composer = 12
    }
    
    public let type: TypeIdentifier
    public let stringValue: String?
}
```

## Timestamp Handling

iTunes databases use Mac epoch timestamps (January 1, 1904) rather than Unix epoch:

```swift
extension ITDBTrack {
    var lastPlayedDate: Date? {
        guard lastPlayed > 0 else { return nil }
        let macEpochOffset: TimeInterval = 2082844800  // Seconds between 1904 and 1970
        let unixTimestamp = TimeInterval(lastPlayed) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }
}
```

## Play Counts Database

The ``PlayCounts`` file stores usage statistics updated by the iPod:

```swift
public struct PlayCounts: IPKParseable {
    let id: String = "mhdp"
    
    public let headerLength: UInt32
    public let entryLength: UInt32       // Size of each entry
    public let numberOfEntries: UInt32   // One per track
    
    public let entries: [PlayCountEntry]
}

public struct PlayCountEntry {
    public let playCount: UInt32         // Times played since last sync
    public let lastPlayed: UInt32        // Mac epoch timestamp
    public let bookmarkTime: UInt32      // Position for podcasts/audiobooks
    public let rating: UInt32            // User rating (0-100)
    public let skipCount: UInt32         // Times skipped
    public let lastSkipped: UInt32       // When last skipped
}
```

The Play Counts file is created and updated by the iPod, then read by iTunes during sync to update the main database.

## Playlist Structures

Playlists are stored in a separate section of the database:

```swift
public struct ITDBPlaylist: IPKParseable {
    let id: String = "mhyp"
    
    public let headerLength: UInt32
    public let playlistLength: UInt32
    public let stringObjectCount: UInt32
    public let listItemsCount: UInt32    // Number of tracks
    public let playlistId: UInt32
    public let playlistType: UInt32      // Regular, smart, etc.
    
    public let name: String?
    public let trackIds: [UInt32]        // References to tracks
}
```

## Binary Format Specifications

### Little-Endian Byte Order

All multi-byte integers in standard iPod databases use little-endian byte order:

```swift
// Reading a UInt32 at offset with little-endian
func readUInt32(at offset: Int) throws -> UInt32 {
    return UInt32(data[offset]) |
           (UInt32(data[offset + 1]) << 8) |
           (UInt32(data[offset + 2]) << 16) |
           (UInt32(data[offset + 3]) << 24)
}
```

### String Encoding

Strings in iTunes databases can use multiple encodings:

1. **UTF-16 Little-Endian**: Most common for metadata
2. **UTF-8**: Alternative encoding
3. **ASCII**: For file paths and simple strings

The parsing framework automatically detects encoding and handles iTunes-specific padding and artifacts.

### Padding and Alignment

Many structures include padding bytes for alignment:

```swift
struct AlignedField: IPKField {
    var offset: Int { 24 }
    var length: Int { 4 }
    // Note: There may be 2 bytes of padding before this field
}
```

## Version Compatibility

Different iPod models use different database versions:

- **Version 0x13**: iPod Video, 5.5G iPod
- **Version 0x14**: iPod Classic
- **Version 0x15**: iPod Touch, iPhone (early versions)

iPodKit handles version differences automatically by checking version numbers and adjusting parsing accordingly.

## Error Recovery

The parsing framework includes robust error recovery:

```swift
// Handle corrupted or truncated data gracefully
for i in 0..<numberOfTracks {
    guard offset + trackSize <= data.count else {
        print("Warning: Truncated track data at index \(i)")
        break
    }
    // Parse track...
}
```

## See Also

- ``iTunesDB``
- ``ITDBTrack``
- ``PlayCounts``
- ``ITDBPlaylist``
- <doc:BinaryParsingFramework>