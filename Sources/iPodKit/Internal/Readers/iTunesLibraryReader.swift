//
//  iTunesLibraryReader.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation
import SQLite

/// High-level reader for SQLite-based iTunes Library files.
///
/// This class reads `Library.itdb` for track metadata and attaches
/// `Dynamic.itdb` for play counts and last-played dates.
///
/// ## Database Structure
///
/// The iTunes Library uses two main SQLite database files:
/// - `Library.itdb` - Contains track metadata (title, artist, album, etc.)
/// - `Dynamic.itdb` - Contains dynamic data (play counts, ratings, etc.)
final class iTunesLibraryReader: Sendable {

    // MARK: - Properties

    let tracks: [ITLibTrack]
    private let _playlists: [ITLibPlaylist]
    let libraryPath: URL
    let dynamicPath: URL

    /// Device name extracted from the root container (e.g., "John's iPod")
    let deviceName: String?

    /// Internal accessor for playlists
    internal var playlists: [ITLibPlaylist] { _playlists }

    // MARK: - Initialization

    /// Initialize from a directory that contains the iTunes Library package.
    /// - Parameter iPodPath: Path to a directory containing the iTunes Library package.
    /// - Throws: IPKParsingError if files not found or parsing fails
    convenience init(iPodPath: String) throws {
        let basePath = URL(fileURLWithPath: iPodPath)
        let libraryPath = basePath.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Library.itdb")
        let dynamicPath = basePath.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Dynamic.itdb")
        try self.init(libraryPath: libraryPath, dynamicPath: dynamicPath)
    }

    /// Initialize with specific database file paths
    /// - Parameters:
    ///   - libraryPath: URL to Library.itdb file
    ///   - dynamicPath: URL to Dynamic.itdb file
    /// - Throws: IPKParsingError if files not found or parsing fails
    init(libraryPath: URL, dynamicPath: URL) throws {
        self.libraryPath = libraryPath
        self.dynamicPath = dynamicPath

        // Verify files exist
        guard FileManager.default.fileExists(atPath: libraryPath.path) else {
            throw IPKParsingError.fileNotFound(libraryPath.path)
        }
        guard FileManager.default.fileExists(atPath: dynamicPath.path) else {
            throw IPKParsingError.fileNotFound(dynamicPath.path)
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
            try db.execute("ATTACH DATABASE \(sqliteStringLiteral(dynamicPath.path)) AS dynamic")

            // Attach Locations database when present (file paths and sizes)
            let locationsPath = libraryPath.deletingLastPathComponent().appendingPathComponent("Locations.itdb")
            var hasLocations = false
            if FileManager.default.fileExists(atPath: locationsPath.path) {
                do {
                    try db.execute("ATTACH DATABASE \(sqliteStringLiteral(locationsPath.path)) AS locations")
                    hasLocations = true
                } catch {
                    // Locations are optional - tracks still load without file paths
                }
            }

            let locationColumns = hasLocations
                ? "bl.path || '/' || l.location, l.file_size"
                : "NULL, NULL"
            let locationJoins = hasLocations
                ? """
                  LEFT JOIN locations.location l ON l.item_pid = i.pid
                  LEFT JOIN locations.base_location bl ON bl.id = l.base_location_id
                  """
                : ""

            let sql = """
                SELECT i.pid, i.title, i.artist, i.album, i.album_artist, g.genre,
                       i.composer, i.comment, i.grouping,
                       i.total_time_ms, i.start_time_ms, i.stop_time_ms,
                       i.track_number, i.track_count, i.disc_number, i.disc_count,
                       i.year, i.bpm, i.is_compilation, i.date_modified,
                       i.is_song, i.is_movie, i.is_podcast, i.is_audio_book,
                       i.is_music_video, i.is_tv_show,
                       a.bit_rate, a.sample_rate,
                       \(locationColumns),
                       s.play_count_user, s.skip_count_user, s.user_rating,
                       s.date_played, s.date_skipped, s.bookmark_time_ms
                FROM item i
                LEFT JOIN genre_map g ON g.id = i.genre_id
                LEFT JOIN avformat_info a ON a.item_pid = i.pid
                LEFT JOIN dynamic.item_stats s ON s.item_pid = i.pid
                \(locationJoins)
                WHERE i.is_digital_booklet = 0 AND i.is_tone = 0 AND i.is_ringtone = 0
                """

            func int(_ value: Binding?) -> Int { Int((value as? Int64) ?? 0) }
            func double(_ value: Binding?) -> Double {
                if let d = value as? Double { return d }
                return Double((value as? Int64) ?? 0)
            }

            var tracks: [ITLibTrack] = []
            for row in try db.prepare(sql) {
                let track = ITLibTrack(
                    pid: (row[0] as? Int64) ?? 0,
                    title: (row[1] as? String) ?? "",
                    artist: (row[2] as? String) ?? "",
                    album: (row[3] as? String) ?? "",
                    albumArtist: row[4] as? String,
                    genre: row[5] as? String,
                    composer: row[6] as? String,
                    comment: row[7] as? String,
                    grouping: row[8] as? String,
                    totalTimeMs: double(row[9]),
                    startTimeMs: double(row[10]),
                    stopTimeMs: double(row[11]),
                    trackNumber: int(row[12]),
                    trackCount: int(row[13]),
                    discNumber: int(row[14]),
                    discCount: int(row[15]),
                    year: int(row[16]),
                    bpm: int(row[17]),
                    isCompilation: int(row[18]) == 1,
                    mediaType: mediaType(
                        isSong: int(row[20]) == 1,
                        isMovie: int(row[21]) == 1,
                        isPodcast: int(row[22]) == 1,
                        isAudiobook: int(row[23]) == 1,
                        isMusicVideo: int(row[24]) == 1,
                        isTVShow: int(row[25]) == 1
                    ),
                    dateModified: (row[19] as? Int64) ?? 0,
                    bitrate: int(row[26]),
                    sampleRate: Int(double(row[27])),
                    location: row[28] as? String,
                    fileSize: (row[29] as? Int64) ?? 0,
                    playCount: int(row[30]),
                    skipCount: int(row[31]),
                    rating: int(row[32]),
                    datePlayed: (row[33] as? Int64) ?? 0,
                    dateSkipped: (row[34] as? Int64) ?? 0,
                    bookmarkTimeMs: double(row[35])
                )
                tracks.append(track)
            }

            // Sort by date played (most recent first), preserving prior behavior
            return tracks.sorted { $0.datePlayed > $1.datePlayed }
        } catch {
            throw IPKParsingError.databaseError(error.localizedDescription)
        }
    }

    private static func mediaType(
        isSong: Bool,
        isMovie: Bool,
        isPodcast: Bool,
        isAudiobook: Bool,
        isMusicVideo: Bool,
        isTVShow: Bool
    ) -> MediaType {
        if isPodcast { return .podcast }
        if isAudiobook { return .audiobook }
        if isMusicVideo { return .musicVideo }
        if isTVShow { return .tvShow }
        if isMovie { return .video }
        if isSong { return .audio }
        return .unknown
    }

    private static func sqliteStringLiteral(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "''"))'"
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
    static func isSupported(iPodPath: String) -> Bool {
        let basePath = URL(fileURLWithPath: iPodPath)
        return isSupported(iPodURL: basePath)
    }

    /// Check if the given iPod URL contains SQLite-based iTunes Library
    /// - Parameter iPodURL: URL to iPod root directory
    /// - Returns: true if SQLite databases are found
    static func isSupported(iPodURL: URL) -> Bool {
        let libraryPath = iPodURL.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Library.itdb")
        let dynamicPath = iPodURL.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Dynamic.itdb")
        let fm = FileManager.default
        return fm.fileExists(atPath: libraryPath.path) && fm.fileExists(atPath: dynamicPath.path)
    }
}

// MARK: - Internal API

extension iTunesLibraryReader {

    /// Get the total number of tracks
    var trackCount: Int {
        return tracks.count
    }

}
