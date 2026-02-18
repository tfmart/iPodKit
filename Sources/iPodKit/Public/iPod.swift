//
//  iPod.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// The main entry point for reading iPod databases.
///
/// Create an `iPod` instance by pointing it at the root directory of a mounted iPod.
/// The initializer automatically detects the database format (binary iTunesDB,
/// iTunesSD for Shuffle, or SQLite for newer models) and loads all available data.
///
/// ```swift
/// let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))
///
/// print(ipod.deviceName ?? "Unknown iPod")
/// print("Tracks: \(ipod.tracks.count)")
///
/// for track in ipod.tracks {
///     print("\(track.title ?? "Unknown") - \(track.artist ?? "Unknown")")
/// }
/// ```
public final class iPod: Sendable {

    // MARK: - Public Properties

    /// URL to the iPod root directory.
    public let url: URL

    /// Device name as configured in iTunes (e.g., "John's iPod").
    ///
    /// Extracted from the master playlist name (binary database) or the
    /// primary container (SQLite database). `nil` if no name is stored.
    public let deviceName: String?

    /// All tracks stored on the iPod.
    ///
    /// Tracks include metadata such as title, artist, album, play count,
    /// and artwork when available. The array is ordered by the track's
    /// position in the database.
    public let tracks: [Track]

    /// All playlists stored on the iPod.
    ///
    /// iPod Shuffle does not support playlists, so this array will be
    /// empty for Shuffle devices.
    public let playlists: [Playlist]

    // MARK: - Initialization

    /// Create an iPod instance from a mounted iPod directory.
    ///
    /// - Parameter url: URL to the iPod root directory (e.g., `/Volumes/iPod`).
    /// - Throws: ``IPKError`` if the database files cannot be read or parsed.
    public init(url: URL) throws {
        self.url = url
        let reader = try iPodDBReader(iPodPath: url.path)
        self.deviceName = reader.deviceName
        var artworkIndex: [UInt64: ArtworkImageItem] = [:]
        if let artworkDB = reader.artworkDB {
            for item in artworkDB.imageItems where !item.thumbnails.isEmpty {
                artworkIndex[item.songId] = item
            }
        }

        self.tracks = Self.buildTracks(from: reader, artworkIndex: artworkIndex, iPodURL: url)
        self.playlists = Self.buildPlaylists(from: reader)
    }
}

// MARK: - Private Helpers

private extension iPod {

    static func buildTracks(from reader: iPodDBReader, artworkIndex: [UInt64: ArtworkImageItem], iPodURL: URL) -> [Track] {
        if let iTunesLibrary = reader.iTunesLibrary {
            return iTunesLibrary.tracks.enumerated().map { index, track in
                let trackId = UInt64(bitPattern: track.pid)
                return Track(track, index: index, artwork: artworkIndex[trackId], iPodURL: iPodURL)
            }
        }

        if let iTunesDB = reader.iTunesDB {
            let playCounts = reader.playCountsDB
            return iTunesDB.tracks.enumerated().map { index, track in
                return Track(track, index: index, playCountEntry: playCounts?.playCountEntry(for: index), artwork: artworkIndex[track.dbid], iPodURL: iPodURL)
            }
        }

        if let shuffleDB = reader.shuffleDB {
            let stats = reader.shuffleStats
            return shuffleDB.tracks.enumerated().map { index, track in
                Track(shuffleTrack: track, index: index, statEntry: stats?.statEntry(for: index))
            }
        }

        return []
    }

    static func buildPlaylists(from reader: iPodDBReader) -> [Playlist] {
        if let iTunesLibrary = reader.iTunesLibrary {
            return iTunesLibrary.playlists.map { Playlist($0) }
        }

        if let iTunesDB = reader.iTunesDB {
            return iTunesDB.playlists.map { Playlist($0) }
        }

        // iPod Shuffle doesn't support playlists
        return []
    }
}
