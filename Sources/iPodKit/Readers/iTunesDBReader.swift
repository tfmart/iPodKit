//
//  iTunesDBReader.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// High-level reader for iTunes database files
///
/// This class provides a convenient interface for reading and parsing
/// iTunes DB files from iPods, handling the hierarchical structure
/// and providing easy access to tracks and playlists.
public final class iTunesDBReader: Sendable {

    // MARK: - Properties

    public let database: iTunesDB
    public let tracks: [ITDBTrack]
    private let _playlists: [ITDBPlaylist]

    /// Internal accessor for playlists
    internal var playlists: [ITDBPlaylist] { _playlists }

    // MARK: - Initialization

    /// Initialize from a file path
    /// - Parameter filePath: Path to the iTunesDB file
    /// - Throws: Parsing or file reading errors
    public convenience init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    /// Initialize from raw data
    /// - Parameter data: Raw iTunesDB file data
    /// - Throws: Parsing errors
    public init(data: Data) throws {
        // Parse the main database header
        self.database = try iTunesDB(from: data)

        // Parse the hierarchical structure
        let (parsedTracks, parsedPlaylists) = try Self.parseDatabase(from: data, database: database)
        self.tracks = parsedTracks
        self._playlists = parsedPlaylists
    }

    // MARK: - Private Static Methods

    private static func parseDatabase(from data: Data, database: iTunesDB) throws -> ([ITDBTrack], [ITDBPlaylist]) {
        var offset = Int(database.headerLength)
        var tracks: [ITDBTrack] = []
        var playlists: [ITDBPlaylist] = []

        // Parse each dataset based on numberOfChildren
        for _ in 0..<database.numberOfChildren {
            guard offset + 16 <= data.count else {
                throw IPKError.insufficientData
            }

            // Read dataset header
            let dataSetData = data.subdata(in: offset..<data.count)
            let dataSet = try iTunesDBDataSet(from: dataSetData)

            let dataSetType = try dataSet.getType(from: dataSetData)

            switch dataSetType {
            case 1: // Track List
                tracks = try parseTrackList(from: dataSetData)
            case 2: // Playlist List
                playlists = try parsePlaylistList(from: dataSetData)
            default:
                // Skip unknown dataset types
                break
            }

            offset += Int(try dataSet.getTotalLength(from: dataSetData))
        }

        return (tracks, playlists)
    }

    private static func parseTrackList(from data: Data) throws -> [ITDBTrack] {
        // Skip dataset header to get to track list
        let trackListOffset = Int(try iTunesDBDataSet.HeaderLength().readUInt32(from: data))
        let trackListData = data.subdata(in: trackListOffset..<data.count)

        let trackList = try ITDBTrackList(from: trackListData)
        let numberOfSongs = try trackList.getNumberOfSongs(from: trackListData)

        var currentOffset = Int(try ITDBTrackList.HeaderLength().readUInt32(from: trackListData))
        var tracks: [ITDBTrack] = []

        // Parse each track
        for _ in 0..<numberOfSongs {
            guard currentOffset < trackListData.count else { break }

            let trackData = trackListData.subdata(in: currentOffset..<trackListData.count)
            let track = try ITDBTrack(from: trackData)
            tracks.append(track)

            currentOffset += Int(track.totalLength)
        }

        return tracks
    }

    private static func parsePlaylistList(from data: Data) throws -> [ITDBPlaylist] {
        // Skip dataset header to get to playlist list
        let playlistListOffset = Int(try iTunesDBDataSet.HeaderLength().readUInt32(from: data))
        let playlistListData = data.subdata(in: playlistListOffset..<data.count)

        let playlistList = try ITDBPlaylistList(from: playlistListData)
        let numberOfPlaylists = try playlistList.getNumberOfPlaylists(from: playlistListData)

        var currentOffset = Int(try ITDBPlaylistList.HeaderLength().readUInt32(from: playlistListData))
        var playlists: [ITDBPlaylist] = []

        // Parse each playlist
        for _ in 0..<numberOfPlaylists {
            guard currentOffset < playlistListData.count else { break }

            let playlistData = playlistListData.subdata(in: currentOffset..<playlistListData.count)
            let playlist = try ITDBPlaylist(from: playlistData)
            playlists.append(playlist)

            currentOffset += Int(try playlist.getTotalLength(from: playlistData))
        }

        return playlists
    }
}

// MARK: - Public API

public extension iTunesDBReader {

    /// Get the total number of tracks
    var trackCount: Int {
        return tracks.count
    }

    /// Get the total number of playlists
    var playlistCount: Int {
        return playlists.count
    }

    /// Get database version information
    var version: UInt32 {
        return database.versionNumber
    }

    /// Get tracks filtered by a predicate
    /// - Parameter predicate: Filter condition
    /// - Returns: Filtered tracks
    func tracks(where predicate: (ITDBTrack) -> Bool) -> [ITDBTrack] {
        return tracks.filter(predicate)
    }

    /// Get track by unique ID
    /// - Parameter id: Track unique ID
    /// - Returns: Track if found
    func track(withId id: UInt32) -> ITDBTrack? {
        return tracks.first { $0.uniqueId == id }
    }

    /// Search tracks by title
    /// - Parameter title: Title to search for (case-insensitive)
    /// - Returns: Tracks matching the title
    func tracks(withTitle title: String) -> [ITDBTrack] {
        return tracks.filter { track in
            track.title?.localizedCaseInsensitiveContains(title) == true
        }
    }

    /// Search tracks by artist
    /// - Parameter artist: Artist to search for (case-insensitive)
    /// - Returns: Tracks by the artist
    func tracks(byArtist artist: String) -> [ITDBTrack] {
        return tracks.filter { track in
            track.artist?.localizedCaseInsensitiveContains(artist) == true
        }
    }

    /// Search tracks by album
    /// - Parameter album: Album to search for (case-insensitive)
    /// - Returns: Tracks from the album
    func tracks(fromAlbum album: String) -> [ITDBTrack] {
        return tracks.filter { track in
            track.album?.localizedCaseInsensitiveContains(album) == true
        }
    }

    /// Get all unique artists
    /// - Returns: Array of unique artist names
    func allArtists() -> [String] {
        let artists = tracks.compactMap { $0.artist }
        return Array(Set(artists)).sorted()
    }

    /// Get all unique albums
    /// - Returns: Array of unique album names
    func allAlbums() -> [String] {
        let albums = tracks.compactMap { $0.album }
        return Array(Set(albums)).sorted()
    }

    /// Get all unique genres
    /// - Returns: Array of unique genre names
    func allGenres() -> [String] {
        let genres = tracks.compactMap { $0.genre }
        return Array(Set(genres)).sorted()
    }

    /// Get tracks that have been played at least once
    /// - Returns: Array of played tracks
    func playedTracks() -> [ITDBTrack] {
        return tracks.filter { $0.playCount > 0 }
    }

    /// Get tracks played after a specific date
    /// - Parameter date: Date to filter from
    /// - Returns: Array of recently played tracks
    func tracks(playedAfter date: Date) -> [ITDBTrack] {
        return tracks.filter { track in
            guard let lastPlayed = track.lastPlayedDate else { return false }
            return lastPlayed > date
        }
    }

    /// Get most played tracks
    /// - Parameter limit: Number of tracks to return
    /// - Returns: Array of most played tracks
    func mostPlayedTracks(limit: Int = 10) -> [ITDBTrack] {
        return tracks
            .filter { $0.playCount > 0 }
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
    }
}
