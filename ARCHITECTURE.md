# Architecture

Developer/maintainer reference for iPodKit's internals. For public API usage, see the DocC documentation.

## How `iPod(url:)` Works

```
iPod.init(url:)
  |
  +-> iPodDBReader(iPodPath:)
  |     |
  |     +-> detectDeviceType()
  |     |     Checks files on disk to classify the iPod:
  |     |       1. SQLite first  (Library.itdb + Dynamic.itdb)
  |     |       2. Shuffle       (iTunesSD at root)
  |     |       3. Photo/Standard (iTunesDB + optional ArtworkDB)
  |     |
  |     +-> loadDatabaseFiles()
  |           Dispatches to format-specific loaders:
  |             .sqliteLibrary -> iTunesLibraryReader (SQLite)
  |             .shuffle       -> iTunesSD parser (big-endian binary)
  |             .photo/.standard -> iTunesDBReader (little-endian binary)
  |           Each loader also picks up optional files:
  |             PlayCounts, ArtworkDB, OTG Playlist, EQ Presets,
  |             iTunesStats, iTunesShuffle, iTunesPState,
  |             Preferences, iPodSettings.xml
  |
  +-> Build artwork index: [UInt64: ArtworkImageItem]
  |     Maps song IDs to their artwork data for O(1) lookup.
  |
  +-> iPod.buildTracks(from:artworkIndex:iPodURL:)
  |     Tries each database format in priority order:
  |       1. iTunesLibrary  -> Track(ITLibTrack)
  |       2. iTunesDB       -> Track(ITDBTrack, PlayCountEntry?)
  |       3. iTunesSD       -> Track(shuffleTrack:, iTunesStatEntry?)
  |
  +-> iPod.buildPlaylists(from:)
        1. iTunesLibrary  -> Playlist(ITLibPlaylist)
        2. iTunesDB       -> Playlist(ITDBPlaylist)
        3. Shuffle has no playlists -> []
```

## Three Database Formats

| Format | iPod Models | Main File | Parser | Endianness |
|--------|-------------|-----------|--------|------------|
| Binary iTunesDB | Classic, Nano 1-5, Mini, Photo | `iPod_Control/iTunes/iTunesDB` | `iTunesDBReader` | Little-endian |
| Binary iTunesSD | Shuffle 1-4 | `iTunesSD` (at root) | `iTunesSD` struct | Big-endian |
| SQLite Library | Nano 6-7 (newer) | `iPod_Control/iTunes/iTunes Library.itlp/Library.itdb` | `iTunesLibraryReader` | N/A (SQLite) |

### Standard iPod Files
- `iTunesDB` - Track and playlist database (mhbd header)
- `Play Counts` - Recent play history (mhdp header)
- `OTG Playlist File` - On-the-go playlists
- `Equalizer Presets` - EQ settings (mqed header)
- `ArtworkDB` - Album artwork (mhfd header)
- `Photo Database` - Photo library (mhfd header)
- `Preferences` - Binary device prefs (timezone at offset 0xB10)
- `iPodSettings.xml` - XML device settings (timezone fallback)

### Shuffle Files
- `iTunesSD` - Track database with 512-byte entries
- `iTunesStats` - Play counts and skip counts
- `iTunesShuffle` - Shuffle order sequence
- `iTunesPState` - Playback state (position, volume, repeat/shuffle mode)

## Binary Parsing Pattern

All binary database types use the `IPKField` + `IPKParseable` pattern:

```swift
// 1. Define field layout as nested structs
extension ITDBTrack {
    struct Identifier: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
}

// 2. Protocol provides type-safe readers
//    readUInt8, readUInt16, readUInt32, readInt32, readUInt64, readBytes
//    Each validates length matches expected byte count.

// 3. Parser init reads fields from raw Data
struct ITDBTrack: IPKParseable {
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhit")
        self.uniqueId = try Self.Identifier().readUInt32(from: data)
        // ...
    }
}
```

Binary helpers live in `Data+Extensions`: `readUInt32(at:)`, `readUTF16String(at:length:)`, `readMHODString(at:length:)`, etc. All use little-endian byte order (except iTunesSD which reads big-endian manually).

## Internal to Public Type Mapping

| Internal Type | Public Type | Conversion |
|---------------|-------------|------------|
| `ITDBTrack` | `Track` | `Track.init(_:index:playCountEntry:artwork:iPodURL:)` |
| `iTunesSDTrack` | `Track` | `Track.init(shuffleTrack:index:statEntry:)` |
| `ITLibTrack` | `Track` | `Track.init(_:index:artwork:iPodURL:)` |
| `ITDBPlaylist` | `Playlist` | `Playlist.init(_:)` |
| `ITLibPlaylist` | `Playlist` | `Playlist.init(_:)` |
| `ArtworkImageItem` | `Artwork` | `Artwork.init(from:iPodURL:)` |
| `PlayCountEntry` | merged into `Track` | Play count, rating, skip count, bookmark |
| `iTunesStatEntry` | merged into `Track` | Play count, rating, skip count for Shuffle |

Internal convenience initializers handle type conversions (UInt32 to Int, Mac epoch to Date, milliseconds to TimeInterval) and merge data from multiple sources (e.g., PlayCounts override iTunesDB play data).

## Folder Map

```
Sources/iPodKit/
├── iPodKit.swift                    Module docs (DocC landing page)
├── Documentation.docc/              DocC articles
├── Public/                          Consumer-facing API
│   ├── iPod.swift                   Main entry point
│   ├── Models/                      Track, Playlist, Artwork, MediaType, iPodModel
│   └── Errors/                      IPKError
└── Internal/                        Implementation details
    ├── Core/
    │   ├── Protocols/               IPKField, IPKParseable
    │   ├── Extensions/              Data+Extensions
    │   ├── Errors/                  IPKParsingError
    │   └── ArtworkDecoder.swift
    ├── Databases/
    │   ├── Standard/                iTunesDB, ITDBTrack, PlayCounts, etc.
    │   ├── Shuffle/                 iTunesSD, iTunesStats, etc.
    │   ├── Media/                   ArtworkDatabase, PhotoDatabase, etc.
    │   └── Playlists/               ITDBPlaylist, OTGPlaylist, etc.
    ├── Models/                      EqualizerPresets (internal model)
    └── Readers/                     iPodDBReader, iTunesDBReader, iTunesLibraryReader
```

**Rule:** Everything in `Public/` is `public`. Nothing in `Internal/` is `public`.
