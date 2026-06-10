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
            throw IPKParsingError.databaseError(error.localizedDescription)
        }
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
