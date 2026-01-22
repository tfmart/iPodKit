//
//  iPod.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// The main entry point for reading iPod databases.
///
/// `iPod` provides a simple, unified API for accessing all data stored on an iPod device.
/// It automatically detects the device type and loads all available database files,
/// merging data from multiple sources into easy-to-use `Track` and `Playlist` objects.
///
/// ## Quick Start
///
/// ```swift
/// // Simple initialization - just provide the path
/// let ipod = try iPod(path: "/Volumes/iPod")
///
/// // Access tracks
/// for track in ipod.tracks {
///     print("\(track.title ?? "Unknown") by \(track.artist ?? "Unknown")")
/// }
///
/// // Get recently played tracks
/// let recent = ipod.recentlyPlayed()
///
/// // Search for tracks
/// let results = ipod.search("Beatles")
/// ```
///
/// ## Advanced Access
///
/// For advanced use cases, access raw databases directly:
///
/// ```swift
/// let ipod = try iPod(path: "/Volumes/iPod")
///
/// // Access raw databases for advanced use cases
/// if let artworkDB = ipod.databases.artwork {
///     // Work with artwork directly
/// }
/// ```
///
/// ## Supported Devices
///
/// iPodKit automatically detects and supports:
/// - Standard iPods / iPod Classic (all generations)
/// - iPod Shuffle (all generations)
/// - iPod Photo / iPod with Color Display
/// - iPod Nano (all generations)
///
/// ## Topics
///
/// ### Creating an iPod Instance
/// - ``init(path:)``
/// - ``configure(path:)``
///
/// ### Accessing Tracks
/// - ``tracks``
/// - ``trackCount``
/// - ``track(withId:)``
///
/// ### Accessing Playlists
/// - ``playlists``
/// - ``playlist(withName:)``
///
/// ### Playback Information
/// - ``recentlyPlayed(limit:)``
/// - ``mostPlayed(limit:)``
/// - ``neverPlayed()``
///
/// ### Search
/// - ``search(_:)``
///
/// ### Device Information
/// - ``deviceType``
/// - ``path``
public final class iPod: Sendable {

    // MARK: - Public Properties

    /// The detected device type
    public let deviceType: DeviceType

    /// URL to the iPod root directory
    public let url: URL

    /// Path to the iPod root directory
    public var path: String { url.path }

    /// All tracks on the iPod, with play count data merged automatically
    public let tracks: [Track]

    /// All playlists on the iPod
    public let playlists: [Playlist]

    /// Access to raw database files for advanced use cases
    public let databases: DatabaseAccess

    /// The device name as stored in the iTunes Library database.
    ///
    /// This is the name assigned to the iPod in iTunes/Finder, if available.
    /// This property is populated from the SQLite-based iTunes Library format.
    ///
    /// > Note: Only available for iPods using the SQLite-based iTunes Library.
    /// > iPods using the binary iTunesDB format do not store the device name.
    public let deviceName: String?

    // MARK: - Device Type

    /// Represents the type of iPod device
    public enum DeviceType: String, Sendable {
        /// Standard iPod with iTunesDB
        case standard = "Standard iPod"
        /// iPod Shuffle with iTunesSD
        case shuffle = "iPod Shuffle"
        /// iPod with photo/artwork support
        case photo = "iPod Photo"
        /// Newer iPod with SQLite-based library
        case sqlite = "iPod (SQLite)"
        /// Unknown device type
        case unknown = "Unknown"
    }

    // MARK: - Initialization

    /// Initialize an iPod instance from a URL.
    ///
    /// This is the simplest way to use iPodKit. The library automatically:
    /// - Detects the device type
    /// - Loads all available database files
    /// - Merges play count data with track metadata
    ///
    /// ```swift
    /// let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))
    /// print("Found \(ipod.trackCount) tracks")
    /// ```
    ///
    /// - Parameter url: URL to the iPod root directory
    /// - Throws: ``IPKError`` if the URL is invalid or database files cannot be parsed
    public convenience init(url: URL) throws {
        try self.init(configuration: Configuration(url: url))
    }

    /// Initialize an iPod instance from a path string.
    ///
    /// This is a convenience initializer that converts the string path to a URL.
    ///
    /// ```swift
    /// let ipod = try iPod(path: "/Volumes/iPod")
    /// print("Found \(ipod.trackCount) tracks")
    /// ```
    ///
    /// - Parameter path: Path to the iPod root directory
    /// - Throws: ``IPKError`` if the path is invalid or database files cannot be parsed
    public convenience init(path: String) throws {
        try self.init(url: URL(fileURLWithPath: path))
    }

    /// Start building a configured iPod instance.
    ///
    /// Use this method for advanced configuration options:
    ///
    /// ```swift
    /// let ipod = try iPod.configure(url: URL(fileURLWithPath: "/Volumes/iPod"))
    ///     .loadArtwork(true)
    ///     .loadPhotos(true)
    ///     .build()
    /// ```
    ///
    /// - Parameter url: URL to the iPod root directory
    /// - Returns: A configuration builder
    public static func configure(url: URL) -> Configuration.Builder {
        Configuration.Builder(url: url)
    }

    /// Start building a configured iPod instance.
    ///
    /// Use this method for advanced configuration options:
    ///
    /// ```swift
    /// let ipod = try iPod.configure(path: "/Volumes/iPod")
    ///     .loadArtwork(true)
    ///     .loadPhotos(true)
    ///     .build()
    /// ```
    ///
    /// - Parameter path: Path to the iPod root directory
    /// - Returns: A configuration builder
    public static func configure(path: String) -> Configuration.Builder {
        Configuration.Builder(url: URL(fileURLWithPath: path))
    }

    // MARK: - Internal Initialization

    internal init(configuration: Configuration) throws {
        self.url = configuration.url

        // Use internal reader to load databases
        let reader = try iPodDBReader(iPodPath: configuration.url.path)

        // Map device type
        self.deviceType = Self.mapDeviceType(reader.deviceType)

        // Build unified track list
        self.tracks = Self.buildTracks(from: reader)

        // Build unified playlist list
        self.playlists = Self.buildPlaylists(from: reader)

        // Create database access wrapper
        self.databases = DatabaseAccess(reader: reader)

        // Extract device name from SQLite database if available
        self.deviceName = reader.iTunesLibrary?.deviceName
    }
}

// MARK: - Static Device Info

public extension iPod {

    /// Get the device name from an iPod's iTunes Library without loading tracks.
    ///
    /// This is a convenience method for quickly extracting the device name
    /// from an iPod without parsing all track data. Works with iPods that
    /// use the SQLite-based iTunes Library format.
    ///
    /// ```swift
    /// if let name = iPod.deviceName(fromPath: "/Volumes/iPod") {
    ///     print("Device is named: \(name)")
    /// }
    /// ```
    ///
    /// - Parameter path: Path to iPod root directory
    /// - Returns: Device name if found, nil otherwise
    static func deviceName(fromPath path: String) -> String? {
        iTunesLibraryReader.deviceName(fromIPodPath: path)
    }

    /// Get the device name from an iPod's iTunes Library without loading tracks.
    ///
    /// - Parameter url: URL to iPod root directory
    /// - Returns: Device name if found, nil otherwise
    static func deviceName(fromURL url: URL) -> String? {
        iTunesLibraryReader.deviceName(fromIPodURL: url)
    }
}

// MARK: - Track Access

public extension iPod {

    /// Total number of tracks on the iPod
    var trackCount: Int {
        tracks.count
    }

    /// Find a track by its unique ID
    ///
    /// - Parameter id: The track's unique identifier
    /// - Returns: The track if found, nil otherwise
    func track(withId id: UInt64) -> Track? {
        tracks.first { $0.id == id }
    }

    /// Find tracks matching a predicate
    ///
    /// - Parameter predicate: Filter condition
    /// - Returns: Matching tracks
    func tracks(where predicate: (Track) -> Bool) -> [Track] {
        tracks.filter(predicate)
    }

    /// Get all unique artists
    var artists: [String] {
        let artistNames = tracks.compactMap { $0.artist }
        return Array(Set(artistNames)).sorted()
    }

    /// Get all unique albums
    var albums: [String] {
        let albumNames = tracks.compactMap { $0.album }
        return Array(Set(albumNames)).sorted()
    }

    /// Get all unique genres
    var genres: [String] {
        let genreNames = tracks.compactMap { $0.genre }
        return Array(Set(genreNames)).sorted()
    }

    /// Get tracks by a specific artist
    ///
    /// - Parameter artist: Artist name (case-insensitive)
    /// - Returns: Tracks by the artist
    func tracks(byArtist artist: String) -> [Track] {
        tracks.filter { $0.artist?.localizedCaseInsensitiveContains(artist) == true }
    }

    /// Get tracks from a specific album
    ///
    /// - Parameter album: Album name (case-insensitive)
    /// - Returns: Tracks from the album
    func tracks(fromAlbum album: String) -> [Track] {
        tracks.filter { $0.album?.localizedCaseInsensitiveContains(album) == true }
    }

    /// Get tracks in a specific genre
    ///
    /// - Parameter genre: Genre name (case-insensitive)
    /// - Returns: Tracks in the genre
    func tracks(inGenre genre: String) -> [Track] {
        tracks.filter { $0.genre?.localizedCaseInsensitiveContains(genre) == true }
    }
}

// MARK: - Playlist Access

public extension iPod {

    /// Total number of playlists on the iPod
    var playlistCount: Int {
        playlists.count
    }

    /// Find a playlist by name
    ///
    /// - Parameter name: Playlist name (case-insensitive)
    /// - Returns: The playlist if found, nil otherwise
    func playlist(withName name: String) -> Playlist? {
        playlists.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    /// Get tracks for a playlist
    ///
    /// - Parameter playlist: The playlist
    /// - Returns: Tracks in the playlist, in order
    func tracks(in playlist: Playlist) -> [Track] {
        playlist.trackIds.compactMap { id in
            track(withId: id)
        }
    }
}

// MARK: - Playback Information

public extension iPod {

    /// Get recently played tracks, sorted by last played date (most recent first).
    ///
    /// ```swift
    /// let recent = ipod.recentlyPlayed(limit: 25)
    /// for track in recent {
    ///     print("\(track.title) - \(track.lastPlayedFormatted)")
    /// }
    /// ```
    ///
    /// - Parameter limit: Maximum number of tracks to return (default: 25)
    /// - Returns: Recently played tracks
    func recentlyPlayed(limit: Int = 25) -> [Track] {
        tracks
            .filter { $0.lastPlayed != nil }
            .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }

    /// Get tracks played after a specific date.
    ///
    /// - Parameter date: The cutoff date
    /// - Returns: Tracks played after the date
    func tracks(playedAfter date: Date) -> [Track] {
        tracks.filter { track in
            guard let lastPlayed = track.lastPlayed else { return false }
            return lastPlayed > date
        }
    }

    /// Get most played tracks, sorted by play count (highest first).
    ///
    /// ```swift
    /// let favorites = ipod.mostPlayed(limit: 10)
    /// for track in favorites {
    ///     print("\(track.title) - \(track.playCount) plays")
    /// }
    /// ```
    ///
    /// - Parameter limit: Maximum number of tracks to return (default: 25)
    /// - Returns: Most played tracks
    func mostPlayed(limit: Int = 25) -> [Track] {
        tracks
            .filter { $0.playCount > 0 }
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
    }

    /// Get tracks that have never been played.
    ///
    /// - Returns: Tracks with zero play count
    func neverPlayed() -> [Track] {
        tracks.filter { $0.playCount == 0 }
    }

    /// Get most skipped tracks.
    ///
    /// - Parameter limit: Maximum number of tracks to return (default: 25)
    /// - Returns: Most skipped tracks
    func mostSkipped(limit: Int = 25) -> [Track] {
        tracks
            .filter { $0.skipCount > 0 }
            .sorted { $0.skipCount > $1.skipCount }
            .prefix(limit)
            .map { $0 }
    }

    /// Get top-rated tracks.
    ///
    /// - Parameter minimumRating: Minimum star rating (1-5, default: 4)
    /// - Returns: Tracks with rating >= minimumRating
    func topRated(minimumRating: Int = 4) -> [Track] {
        tracks
            .filter { $0.rating >= minimumRating }
            .sorted { $0.rating > $1.rating }
    }
}

// MARK: - Search

public extension iPod {

    /// Search for tracks matching a query.
    ///
    /// Searches across title, artist, album, and genre fields.
    ///
    /// ```swift
    /// let results = ipod.search("Beatles")
    /// print("Found \(results.count) matching tracks")
    /// ```
    ///
    /// - Parameter query: Search query (case-insensitive)
    /// - Returns: Matching tracks
    func search(_ query: String) -> [Track] {
        guard !query.isEmpty else { return [] }

        return tracks.filter { track in
            track.title?.localizedCaseInsensitiveContains(query) == true ||
            track.artist?.localizedCaseInsensitiveContains(query) == true ||
            track.album?.localizedCaseInsensitiveContains(query) == true ||
            track.genre?.localizedCaseInsensitiveContains(query) == true
        }
    }
}

// MARK: - Statistics

public extension iPod {

    /// Total play count across all tracks
    var totalPlayCount: UInt64 {
        tracks.reduce(0) { $0 + UInt64($1.playCount) }
    }

    /// Total duration of all tracks
    var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }

    /// Total duration formatted as a string
    var totalDurationFormatted: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }

    /// Total file size of all tracks
    var totalSize: UInt64 {
        tracks.reduce(0) { $0 + $1.fileSize }
    }

    /// Total file size formatted as a string
    var totalSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSize))
    }
}

// MARK: - Private Helpers

private extension iPod {

    static func mapDeviceType(_ readerType: iPodDBReader.iPodDeviceType) -> DeviceType {
        switch readerType {
        case .standard: return .standard
        case .shuffle: return .shuffle
        case .photo: return .photo
        case .sqliteLibrary: return .sqlite
        case .unknown: return .unknown
        }
    }

    static func buildTracks(from reader: iPodDBReader) -> [Track] {
        var unifiedTracks: [Track] = []

        // SQLite-based iTunes Library format
        if let iTunesLibrary = reader.iTunesLibrary {
            for (index, itLibTrack) in iTunesLibrary.tracks.enumerated() {
                let track = Track.from(itLibTrack, index: index)
                unifiedTracks.append(track)
            }
        }
        // Standard iPod with iTunesDB
        else if let iTunesDB = reader.iTunesDB {
            let playCounts = reader.playCountsDB

            for (index, itdbTrack) in iTunesDB.tracks.enumerated() {
                let playCountEntry = playCounts?.playCountEntry(for: index)
                let track = Track.from(itdbTrack, index: index, playCountEntry: playCountEntry)
                unifiedTracks.append(track)
            }
        }
        // iPod Shuffle with iTunesSD
        else if let shuffleDB = reader.shuffleDB {
            let stats = reader.shuffleStats

            for (index, shuffleTrack) in shuffleDB.tracks.enumerated() {
                let statEntry = stats?.statEntry(for: index)
                let track = Track.from(shuffleTrack: shuffleTrack, index: index, statEntry: statEntry)
                unifiedTracks.append(track)
            }
        }

        return unifiedTracks
    }

    static func buildPlaylists(from reader: iPodDBReader) -> [Playlist] {
        var playlists: [Playlist] = []

        // Standard iPod with iTunesDB
        if let iTunesDB = reader.iTunesDB {
            // Build a mapping from iTunesDB track uniqueId to unified Track id
            var trackIdMap: [UInt32: UInt64] = [:]
            for itdbTrack in iTunesDB.tracks {
                // The unified Track uses uniqueId as its id
                trackIdMap[itdbTrack.uniqueId] = UInt64(itdbTrack.uniqueId)
            }

            for itdbPlaylist in iTunesDB.playlists {
                var playlist = Playlist.from(itdbPlaylist)

                // Map the iTunesDB track IDs to unified Track IDs
                let mappedTrackIds = itdbPlaylist.trackIds.compactMap { trackIdMap[$0] }
                playlist = Playlist(
                    id: playlist.id,
                    name: playlist.name,
                    isMasterPlaylist: playlist.isMasterPlaylist,
                    isPodcast: playlist.isPodcast,
                    trackCount: mappedTrackIds.count,
                    trackIds: mappedTrackIds,
                    timestamp: playlist.timestamp
                )

                playlists.append(playlist)
            }
        }

        // SQLite-based iTunes Library
        if let iTunesLibrary = reader.iTunesLibrary {
            let libraryPlaylists = Self.buildSQLitePlaylists(from: iTunesLibrary)
            playlists.append(contentsOf: libraryPlaylists)
        }

        return playlists
    }

    static func buildSQLitePlaylists(from library: iTunesLibraryReader) -> [Playlist] {
        // SQLite library playlists are parsed separately
        return library.playlists.map { libPlaylist in
            Playlist.from(
                id: UInt64(bitPattern: libPlaylist.id),
                name: libPlaylist.name,
                trackIds: libPlaylist.trackPids.map { UInt64(bitPattern: $0) },
                isMasterPlaylist: libPlaylist.isMasterPlaylist
            )
        }
    }
}

// MARK: - Configuration

extension iPod {

    /// Configuration options for iPod initialization.
    ///
    /// Use ``iPod/configure(url:)`` or ``iPod/configure(path:)`` to create a builder:
    ///
    /// ```swift
    /// let ipod = try iPod.configure(url: URL(fileURLWithPath: "/Volumes/iPod"))
    ///     .build()
    /// ```
    public struct Configuration: Sendable {

        /// URL to the iPod root directory
        public let url: URL

        internal init(url: URL) {
            self.url = url
        }

        /// Builder for creating iPod configurations with progressive disclosure.
        ///
        /// ```swift
        /// let ipod = try iPod.configure(url: URL(fileURLWithPath: "/Volumes/iPod"))
        ///     .build()
        /// ```
        public final class Builder: Sendable {
            private let url: URL

            internal init(url: URL) {
                self.url = url
            }

            /// Build the iPod instance with the configured options.
            ///
            /// - Throws: ``IPKError`` if the URL is invalid or database files cannot be parsed
            /// - Returns: Configured iPod instance
            public func build() throws -> iPod {
                let configuration = Configuration(url: url)
                return try iPod(configuration: configuration)
            }
        }
    }
}

// MARK: - Database Access

extension iPod {

    /// Provides access to raw database files for advanced use cases.
    ///
    /// Most users won't need this - use the unified `tracks` and `playlists` properties instead.
    /// This is provided for power users who need direct access to the underlying data structures.
    ///
    /// ```swift
    /// // Only use this if you need raw database access
    /// if let artworkDB = ipod.databases.artwork {
    ///     for image in artworkDB.images {
    ///         print("Image: \(image.imageId)")
    ///     }
    /// }
    /// ```
    public struct DatabaseAccess: Sendable {

        /// Raw iTunesDB reader (standard iPods)
        public let iTunesDB: iTunesDBReader?

        /// Raw Play Counts database
        public let playCounts: PlayCounts?

        /// Raw OTG Playlist
        public let otgPlaylist: OTGPlaylist?

        /// Raw Equalizer Presets
        public let equalizerPresets: EqualizerPresets?

        /// Raw Artwork Database
        public let artwork: ArtworkDatabase?

        /// Raw Photo Database
        public let photos: PhotoDatabase?

        /// Raw iTunesSD (iPod Shuffle)
        public let shuffleDB: iTunesSD?

        /// Raw iTunes Stats (iPod Shuffle)
        public let shuffleStats: iTunesStats?

        /// Raw iTunes Shuffle order
        public let shuffleOrder: iTunesShuffle?

        /// Raw Playback State (iPod Shuffle)
        public let playbackState: iTunesPState?

        /// Raw iTunes Library (SQLite-based)
        public let iTunesLibrary: iTunesLibraryReader?

        internal init(reader: iPodDBReader) {
            self.iTunesDB = reader.iTunesDB
            self.playCounts = reader.playCountsDB
            self.otgPlaylist = reader.otgPlaylist
            self.equalizerPresets = reader.equalizerPresets
            self.artwork = reader.artworkDB
            self.photos = reader.photoDB
            self.shuffleDB = reader.shuffleDB
            self.shuffleStats = reader.shuffleStats
            self.shuffleOrder = reader.shuffleOrder
            self.playbackState = reader.playbackState
            self.iTunesLibrary = reader.iTunesLibrary
        }
    }
}
