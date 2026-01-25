//
//  iTunesLibraryReader.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation
import SQLite

/// Track information from SQLite-based iTunes Library
struct ITLibTrack: Sendable {
    public let pid: Int64
    public let title: String
    public let artist: String
    public let album: String
    public let totalTimeMs: Double
    public let playCount: Int
    public let datePlayed: Int64  // Core Data timestamp (seconds since Jan 1, 2001)

    /// Last played date converted from Core Data timestamp
    public var lastPlayedDate: Date? {
        guard datePlayed > 0 else { return nil }
        // Core Data timestamp: seconds since Jan 1, 2001
        // Jan 1, 2001 00:00:00 UTC = Unix timestamp 978307200
        let coreDataEpochOffset: TimeInterval = 978307200
        return Date(timeIntervalSince1970: Double(datePlayed) + coreDataEpochOffset)
    }

    /// Track duration in seconds
    public var durationInSeconds: Double {
        return totalTimeMs / 1000.0
    }

}

/// Playlist information from SQLite-based iTunes Library
struct ITLibPlaylist: Sendable {
    let id: Int64
    let name: String
    let isMasterPlaylist: Bool
    let trackPids: [Int64]
}

/// Error types for iTunes Library Reader
enum iTunesLibraryReaderError: Error, Sendable {
    case fileNotFound(String)
    case databaseError(String)
}

/// High-level reader for SQLite-based iTunes Library files.
///
/// This class provides a convenient interface for reading and parsing
/// iTunes Library files from iPods that use the SQLite-based library format
/// instead of the binary iTunesDB format.
///
/// ## Usage
///
/// ```swift
/// // Parse iTunes Library from iPod
/// let reader = try iTunesLibraryReader(iPodPath: "/Volumes/iPod")
///
/// print("Tracks: \(reader.trackCount)")
/// for track in reader.playedTracks() {
///     print("\(track.title) by \(track.artist)")
/// }
/// ```
///
/// ## Database Structure
///
/// The iTunes Library uses two main SQLite database files:
/// - `Library.itdb` - Contains track metadata (title, artist, album, etc.)
/// - `Dynamic.itdb` - Contains dynamic data (play counts, ratings, etc.)
final class iTunesLibraryReader: Sendable {

    // MARK: - Properties

    public let tracks: [ITLibTrack]
    private let _playlists: [ITLibPlaylist]
    public let libraryPath: URL
    public let dynamicPath: URL

    /// Device name extracted from the root container (e.g., "John's iPod")
    public let deviceName: String?

    /// Internal accessor for playlists
    internal var playlists: [ITLibPlaylist] { _playlists }

    // MARK: - Initialization

    /// Initialize from iPod root directory
    /// - Parameter iPodPath: Path to iPod root directory (e.g., "/Volumes/iPod")
    /// - Throws: iTunesLibraryReaderError if files not found or parsing fails
    public convenience init(iPodPath: String) throws {
        let basePath = URL(fileURLWithPath: iPodPath)
        let libraryPath = basePath.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Library.itdb")
        let dynamicPath = basePath.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Dynamic.itdb")
        try self.init(libraryPath: libraryPath, dynamicPath: dynamicPath)
    }

    /// Initialize with specific database file paths
    /// - Parameters:
    ///   - libraryPath: URL to Library.itdb file
    ///   - dynamicPath: URL to Dynamic.itdb file
    /// - Throws: iTunesLibraryReaderError if files not found or parsing fails
    public init(libraryPath: URL, dynamicPath: URL) throws {
        self.libraryPath = libraryPath
        self.dynamicPath = dynamicPath

        // Verify files exist
        guard FileManager.default.fileExists(atPath: libraryPath.path) else {
            throw iTunesLibraryReaderError.fileNotFound(libraryPath.path)
        }
        guard FileManager.default.fileExists(atPath: dynamicPath.path) else {
            throw iTunesLibraryReaderError.fileNotFound(dynamicPath.path)
        }

        // Parse the databases
        self.tracks = try Self.parseDatabase(libraryPath: libraryPath, dynamicPath: dynamicPath)

        // Parse playlists from container table
        self._playlists = Self.parsePlaylists(libraryPath: libraryPath)

        // Extract device name from root container
        self.deviceName = Self.parseDeviceName(libraryPath: libraryPath)
    }

    // MARK: - Private Methods

    private static func parseDatabase(libraryPath: URL, dynamicPath: URL) throws -> [ITLibTrack] {
        do {
            // Open Library database
            let db = try Connection(libraryPath.path, readonly: true)

            // Attach Dynamic database
            try db.execute("ATTACH DATABASE '\(dynamicPath.path)' AS dynamic")

            // First, get tracks from item table
            let itemTable = Table("item")
            let pid = Expression<Int64>("pid")
            let title = Expression<String?>("title")
            let artist = Expression<String?>("artist")
            let album = Expression<String?>("album")
            let totalTimeMs = Expression<Double?>("total_time_ms")
            let isSong = Expression<Int64?>("is_song")

            // Query songs from Library database
            let songQuery = itemTable
                .filter(isSong == 1)
                .select(pid, title, artist, album, totalTimeMs)

            var trackMap: [Int64: ITLibTrack] = [:]

            for row in try db.prepare(songQuery) {
                let track = ITLibTrack(
                    pid: row[pid],
                    title: row[title] ?? "",
                    artist: row[artist] ?? "",
                    album: row[album] ?? "",
                    totalTimeMs: row[totalTimeMs] ?? 0,
                    playCount: 0,
                    datePlayed: 0
                )
                trackMap[row[pid]] = track
            }

            // Now query play stats from Dynamic database using raw SQL
            // (attached database access works better with raw SQL)
            let statsSQL = "SELECT item_pid, play_count_user, date_played FROM dynamic.item_stats"
            for row in try db.prepare(statsSQL) {
                if let itemPid = row[0] as? Int64,
                   var track = trackMap[itemPid] {
                    let playCount = (row[1] as? Int64) ?? 0
                    let datePlayed = (row[2] as? Int64) ?? 0

                    // Create updated track with play stats
                    track = ITLibTrack(
                        pid: track.pid,
                        title: track.title,
                        artist: track.artist,
                        album: track.album,
                        totalTimeMs: track.totalTimeMs,
                        playCount: Int(playCount),
                        datePlayed: datePlayed
                    )
                    trackMap[itemPid] = track
                }
            }

            // Convert to array and sort by date played (most recent first)
            let tracks = Array(trackMap.values).sorted { track1, track2 in
                track1.datePlayed > track2.datePlayed
            }

            return tracks
        } catch {
            throw iTunesLibraryReaderError.databaseError(error.localizedDescription)
        }
    }

    /// Parses playlists from the container and item_to_container tables.
    ///
    /// Playlists in iTunes Library are stored as containers.
    /// The item_to_container table links containers to their track items.
    private static func parsePlaylists(libraryPath: URL) -> [ITLibPlaylist] {
        var playlists: [ITLibPlaylist] = []

        do {
            let db = try Connection(libraryPath.path, readonly: true)

            // Query user playlists:
            // - Must have items (tracks)
            // - Exclude folders (containers that have children)
            // - Exclude system playlists (distinguished_kind != 0)
            // - Exclude device sync playlists (containers with no parent that match device name pattern)
            let playlistQuery = """
                SELECT c.pid, c.name, c.distinguished_kind, c.parent_pid
                FROM container c
                WHERE c.pid IN (SELECT DISTINCT container_pid FROM item_to_container)
                  AND c.pid NOT IN (SELECT DISTINCT parent_pid FROM container WHERE parent_pid != 0)
                  AND c.distinguished_kind = 0
                  AND c.parent_pid != 0
                ORDER BY c.name
                """

            var playlistData: [(id: Int64, name: String, isMaster: Bool)] = []

            for row in try db.prepare(playlistQuery) {
                if let pid = row[0] as? Int64,
                   let name = row[1] as? String {
                    let distinguishedKind = row[2] as? Int64 ?? 0
                    // distinguished_kind = 4 is typically the "Music" or master playlist
                    let isMaster = distinguishedKind == 4
                    playlistData.append((id: pid, name: name, isMaster: isMaster))
                }
            }

            // For each playlist, get its track PIDs
            for playlist in playlistData {
                let trackQuery = """
                    SELECT item_pid FROM item_to_container
                    WHERE container_pid = \(playlist.id)
                    ORDER BY physical_order
                    """

                var trackPids: [Int64] = []
                for row in try db.prepare(trackQuery) {
                    if let itemPid = row[0] as? Int64 {
                        trackPids.append(itemPid)
                    }
                }

                let libPlaylist = ITLibPlaylist(
                    id: playlist.id,
                    name: playlist.name,
                    isMasterPlaylist: playlist.isMaster,
                    trackPids: trackPids
                )
                playlists.append(libPlaylist)
            }
        } catch {
            // Silently return empty - playlists are optional
        }

        return playlists
    }

    /// Parses the device name from the primary container referenced in db_info.
    ///
    /// The device name (e.g., "John's iPod") is stored in the container table.
    /// The primary container ID is stored in db_info.primary_container_pid.
    private static func parseDeviceName(libraryPath: URL) -> String? {
        do {
            let db = try Connection(libraryPath.path, readonly: true)

            // Get the device name from the primary container
            // db_info.primary_container_pid references the main library container
            let query = """
                SELECT c.name FROM container c
                JOIN db_info d ON c.pid = d.primary_container_pid
                """

            for row in try db.prepare(query) {
                if let name = row[0] as? String {
                    return name
                }
            }
        } catch {
            // Silently return nil - device name is optional
        }

        return nil
    }

    // MARK: - Static Methods

    /// Check if the given iPod path contains SQLite-based iTunes Library
    /// - Parameter iPodPath: Path to iPod root directory
    /// - Returns: true if SQLite databases are found
    public static func isSupported(iPodPath: String) -> Bool {
        let basePath = URL(fileURLWithPath: iPodPath)
        return isSupported(iPodURL: basePath)
    }

    /// Check if the given iPod URL contains SQLite-based iTunes Library
    /// - Parameter iPodURL: URL to iPod root directory
    /// - Returns: true if SQLite databases are found
    public static func isSupported(iPodURL: URL) -> Bool {
        let libraryPath = iPodURL.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Library.itdb")
        let dynamicPath = iPodURL.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Dynamic.itdb")
        let fm = FileManager.default
        return fm.fileExists(atPath: libraryPath.path) && fm.fileExists(atPath: dynamicPath.path)
    }
}

// MARK: - Public API

extension iTunesLibraryReader {

    /// Get the total number of tracks
    var trackCount: Int {
        return tracks.count
    }

    /// Get tracks filtered by a predicate
    /// - Parameter predicate: Filter condition
    /// - Returns: Filtered tracks
    func tracks(where predicate: (ITLibTrack) -> Bool) -> [ITLibTrack] {
        return tracks.filter(predicate)
    }

    /// Get track by unique ID (pid)
    /// - Parameter pid: Track unique ID
    /// - Returns: Track if found
    func track(withPid pid: Int64) -> ITLibTrack? {
        return tracks.first { $0.pid == pid }
    }

    /// Search tracks by title
    /// - Parameter title: Title to search for (case-insensitive)
    /// - Returns: Tracks matching the title
    func tracks(withTitle title: String) -> [ITLibTrack] {
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(title)
        }
    }

    /// Search tracks by artist
    /// - Parameter artist: Artist to search for (case-insensitive)
    /// - Returns: Tracks by the artist
    func tracks(byArtist artist: String) -> [ITLibTrack] {
        return tracks.filter { track in
            track.artist.localizedCaseInsensitiveContains(artist)
        }
    }

    /// Search tracks by album
    /// - Parameter album: Album to search for (case-insensitive)
    /// - Returns: Tracks from the album
    func tracks(fromAlbum album: String) -> [ITLibTrack] {
        return tracks.filter { track in
            track.album.localizedCaseInsensitiveContains(album)
        }
    }

    /// Get all unique artists
    /// - Returns: Array of unique artist names
    func allArtists() -> [String] {
        let artists = tracks.compactMap { $0.artist.isEmpty ? nil : $0.artist }
        return Array(Set(artists)).sorted()
    }

    /// Get all unique albums
    /// - Returns: Array of unique album names
    func allAlbums() -> [String] {
        let albums = tracks.compactMap { $0.album.isEmpty ? nil : $0.album }
        return Array(Set(albums)).sorted()
    }

    /// Get tracks that have been played at least once
    /// - Returns: Array of played tracks
    func playedTracks() -> [ITLibTrack] {
        return tracks.filter { $0.playCount > 0 }
    }

    /// Get tracks played after a specific date
    /// - Parameter date: Date to filter from
    /// - Returns: Array of recently played tracks
    func tracks(playedAfter date: Date) -> [ITLibTrack] {
        return tracks.filter { track in
            guard let lastPlayed = track.lastPlayedDate else { return false }
            return lastPlayed > date
        }
    }

    /// Get most played tracks
    /// - Parameter limit: Number of tracks to return
    /// - Returns: Array of most played tracks
    func mostPlayedTracks(limit: Int = 10) -> [ITLibTrack] {
        return tracks
            .filter { $0.playCount > 0 }
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
    }

    /// Get most recently played tracks
    /// - Parameter limit: Number of tracks to return
    /// - Returns: Array of most recently played tracks
    func recentlyPlayedTracks(limit: Int = 10) -> [ITLibTrack] {
        return tracks
            .filter { $0.lastPlayedDate != nil }
            .sorted { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}
