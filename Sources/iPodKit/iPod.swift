//
//  iPod.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// The main entry point for reading iPod databases.
///
/// ```swift
/// let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))
/// print("Tracks: \(ipod.tracks.count)")
/// print("Playlists: \(ipod.playlists.count)")
/// ```
public final class iPod: Sendable {

    // MARK: - Public Properties

    /// URL to the iPod root directory
    public let url: URL

    /// Path to the iPod root directory
    public var path: String { url.path }

    /// Device name as configured in iTunes
    public let deviceName: String?

    /// All tracks on the iPod
    public let tracks: [Track]

    /// All playlists on the iPod
    public let playlists: [Playlist]

    // MARK: - Initialization

    /// Initialize an iPod instance from a URL.
    ///
    /// - Parameter url: URL to the iPod root directory
    /// - Throws: ``IPKError`` if the URL is invalid or database files cannot be parsed
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
                return Track.from(track, index: index, artwork: artworkIndex[trackId], iPodURL: iPodURL)
            }
        }

        if let iTunesDB = reader.iTunesDB {
            let playCounts = reader.playCountsDB
            return iTunesDB.tracks.enumerated().map { index, track in
                return Track.from(track, index: index, playCountEntry: playCounts?.playCountEntry(for: index), artwork: artworkIndex[track.dbid], iPodURL: iPodURL)
            }
        }

        if let shuffleDB = reader.shuffleDB {
            let stats = reader.shuffleStats
            return shuffleDB.tracks.enumerated().map { index, track in
                Track.from(shuffleTrack: track, index: index, statEntry: stats?.statEntry(for: index))
            }
        }

        return []
    }

    static func buildPlaylists(from reader: iPodDBReader) -> [Playlist] {
        if let iTunesLibrary = reader.iTunesLibrary {
            return iTunesLibrary.playlists.map { Playlist.from($0) }
        }

        if let iTunesDB = reader.iTunesDB {
            return iTunesDB.playlists.map { Playlist.from($0) }
        }

        // iPod Shuffle doesn't support playlists
        return []
    }
}
