//
//  iPod.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// The main entry point for reading iPod databases.
///
/// Create an `iPod` instance with a URL to a supported database file or to a
/// directory that contains one. The initializer loads the tracks, playlists,
/// playback metadata, and artwork metadata it can find.
///
/// ```swift
/// let ipod = try iPod(contentsOf: databaseURL)
///
/// print(ipod.deviceName ?? "Unknown iPod")
/// print("Tracks: \(ipod.tracks.count)")
/// print("Playlists: \(ipod.playlists.count)")
///
/// for playlist in ipod.playlists {
///     print("\(playlist.name): \(playlist.tracks.count) tracks")
/// }
/// ```
public struct iPod: Sendable {

    // MARK: - Public Properties

    /// URL used to load the database.
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
    /// This array is empty when the loaded database does not contain playlist
    /// records.
    public let playlists: [Playlist]

    // MARK: - Initialization

    /// Create an iPod instance from a supported database file or directory.
    ///
    /// - Parameter url: URL to a supported database file or containing directory.
    /// - Throws: ``iPodError`` if the database files cannot be read or parsed.
    public init(contentsOf url: URL) throws(iPodError) {
        self.url = url
        let reader: iPodDBReader
        do {
            reader = try iPodDBReader(contentsOf: url)
        } catch let error as iPodError {
            throw error
        } catch let error as IPKParsingError {
            throw Self.publicError(from: error)
        } catch {
            throw iPodError.databaseError("The database could not be read.")
        }

        self.deviceName = reader.deviceName
        var artworkIndex: [UInt64: ArtworkImageItem] = [:]
        if let artworkDB = reader.artworkDB {
            for item in artworkDB.imageItems where !item.thumbnails.isEmpty {
                artworkIndex[item.songId] = item
            }
        }

        let tracks = Self.buildTracks(from: reader, artworkIndex: artworkIndex, iPodURL: URL(fileURLWithPath: reader.basePath))
        self.tracks = tracks
        self.playlists = Self.buildPlaylists(from: reader, tracks: tracks)
    }
}

// MARK: - Private Helpers

private extension iPod {

    static func publicError(from error: IPKParsingError) -> iPodError {
        switch error {
        case .fileNotFound(let path):
            return .invalidPath(path)
        case .databaseError:
            return .databaseError("The database could not be read.")
        case .invalidOffset, .invalidString, .invalidMagicNumber, .insufficientData, .fieldSizeMismatch:
            return .corruptedData
        }
    }

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

    static func buildPlaylists(from reader: iPodDBReader, tracks: [Track]) -> [Playlist] {
        if let iTunesLibrary = reader.iTunesLibrary {
            let tracksById = Dictionary(tracks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            return iTunesLibrary.playlists.map { playlist in
                let playlistTracks = playlist.trackPids.compactMap { tracksById[UInt64(bitPattern: $0)] }
                return Playlist(playlist, tracks: playlistTracks)
            }
        }

        if let iTunesDB = reader.iTunesDB {
            let trackPairs = zip(iTunesDB.tracks.map(\.uniqueId), tracks).map { pair in
                (pair.0, pair.1)
            }
            let tracksByUniqueId = Dictionary(trackPairs, uniquingKeysWith: { first, _ in first })
            return iTunesDB.playlists.map { playlist in
                let playlistTracks = playlist.trackIds.compactMap { tracksByUniqueId[$0] }
                return Playlist(playlist, tracks: playlistTracks)
            }
        }

        // Some database files don't include playlist records.
        return []
    }
}
