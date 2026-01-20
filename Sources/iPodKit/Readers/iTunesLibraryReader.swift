//
//  iTunesLibraryReader.swift
//  iPodKit
//
//  Created by Claude on 20/01/26.
//

import Foundation
import SQLite

/// Track information from SQLite-based iTunes Library
public struct ITLibTrack: Sendable {
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

    /// Track duration formatted as MM:SS
    public var durationFormatted: String {
        let totalSeconds = Int(durationInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted last played date string
    public var lastPlayedFormatted: String {
        guard let date = lastPlayedDate else { return "Never played" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Display name for the track
    public var displayName: String {
        if !title.isEmpty {
            return title
        }
        return "Unknown Track"
    }
}

/// Error types for iTunes Library Reader
public enum iTunesLibraryReaderError: Error, Sendable {
    case fileNotFound(String)
    case databaseError(String)
}

/// High-level reader for SQLite-based iTunes Library files (newer iPods)
///
/// This class provides a convenient interface for reading and parsing
/// iTunes Library files from newer iPod models (iPod Nano 6th/7th gen, etc.)
/// that use SQLite databases instead of the binary iTunesDB format.
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
public final class iTunesLibraryReader: Sendable {

    // MARK: - Properties

    public let tracks: [ITLibTrack]
    public let libraryPath: URL
    public let dynamicPath: URL

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

    /// Initialize from iPod root URL
    /// - Parameter iPodURL: URL to iPod root directory
    /// - Throws: iTunesLibraryReaderError if files not found or parsing fails
    public convenience init(iPodURL: URL) throws {
        let libraryPath = iPodURL.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Library.itdb")
        let dynamicPath = iPodURL.appendingPathComponent("iPod_Control/iTunes/iTunes Library.itlp/Dynamic.itdb")
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
    }

    // MARK: - Private Methods

    private static func parseDatabase(libraryPath: URL, dynamicPath: URL) throws -> [ITLibTrack] {
        do {
            // Open Library database
            let db = try Connection(libraryPath.path, readonly: true)

            // Attach Dynamic database
            try db.execute("ATTACH DATABASE '\(dynamicPath.path)' AS dynamic")

            // Define table and columns
            let item = Table("item")
            let itemStats = Table("dynamic.item_stats")

            let pid = Expression<Int64>("pid")
            let itemPid = Expression<Int64>("item_pid")
            let title = Expression<String?>("title")
            let artist = Expression<String?>("artist")
            let album = Expression<String?>("album")
            let totalTimeMs = Expression<Double?>("total_time_ms")
            let isSong = Expression<Int64?>("is_song")
            let playCountUser = Expression<Int64?>("play_count_user")
            let datePlayed = Expression<Int64?>("date_played")

            // Query tracks with play stats using LEFT JOIN
            let query = item
                .join(.leftOuter, itemStats, on: pid == itemPid)
                .filter(isSong == 1)
                .order(datePlayed.desc)
                .select(pid, title, artist, album, totalTimeMs, playCountUser, datePlayed)

            var tracks: [ITLibTrack] = []

            for row in try db.prepare(query) {
                let track = ITLibTrack(
                    pid: row[pid],
                    title: row[title] ?? "",
                    artist: row[artist] ?? "",
                    album: row[album] ?? "",
                    totalTimeMs: row[totalTimeMs] ?? 0,
                    playCount: Int(row[playCountUser] ?? 0),
                    datePlayed: row[datePlayed] ?? 0
                )
                tracks.append(track)
            }

            return tracks
        } catch {
            throw iTunesLibraryReaderError.databaseError(error.localizedDescription)
        }
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

public extension iTunesLibraryReader {

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
