//
//  Track.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// A unified track representation that abstracts away the underlying database format.
///
/// `Track` provides a simple, consistent interface for accessing track metadata
/// regardless of whether the data comes from iTunesDB, Play Counts, iTunesStats,
/// or SQLite-based iTunes Library files.
///
/// ## Usage
///
/// ```swift
/// let ipod = try iPod(path: "/Volumes/iPod")
///
/// for track in ipod.tracks {
///     print("\(track.title) by \(track.artist)")
///     print("Played \(track.playCount) times")
///     if let lastPlayed = track.lastPlayed {
///         print("Last played: \(lastPlayed)")
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Track Metadata
/// - ``title``
/// - ``artist``
/// - ``album``
/// - ``genre``
/// - ``composer``
///
/// ### Playback Information
/// - ``playCount``
/// - ``skipCount``
/// - ``lastPlayed``
/// - ``rating``
/// - ``bookmark``
///
/// ### Audio Properties
/// - ``duration``
/// - ``fileSize``
/// - ``bitrate``
/// - ``sampleRate``
public struct Track: Sendable, Identifiable, Hashable {

    // MARK: - Identification

    /// Unique identifier for this track
    public let id: UInt64

    /// Internal index used for cross-referencing with play counts
    internal let index: Int

    // MARK: - Metadata

    /// Track title
    public let title: String?

    /// Artist name
    public let artist: String?

    /// Album name
    public let album: String?

    /// Genre
    public let genre: String?

    /// Composer
    public let composer: String?

    /// Comment or description
    public let comment: String?

    /// Track grouping
    public let grouping: String?

    /// File path on the iPod
    public let location: String?

    // MARK: - Audio Properties

    /// Track duration in seconds
    public let duration: TimeInterval

    /// File size in bytes
    public let fileSize: UInt64

    /// Audio bitrate in kbps
    public let bitrate: UInt32

    /// Sample rate in Hz
    public let sampleRate: UInt32

    /// Track number on the album
    public let trackNumber: UInt32

    /// Total tracks on the album
    public let totalTracks: UInt32

    /// Release year
    public let year: UInt32

    // MARK: - User Data

    /// Number of times the track has been played
    public let playCount: UInt32

    /// Number of times the track has been skipped
    public let skipCount: UInt32

    /// Star rating (0-5)
    public let rating: Int

    /// Date the track was last played
    public let lastPlayed: Date?

    /// Date the track was last skipped
    public let lastSkipped: Date?

    /// Bookmark position in seconds (for resumable playback)
    public let bookmark: TimeInterval?

    /// Date the track was added to the library
    public let dateAdded: Date?

    /// Date the track was last modified
    public let dateModified: Date?

    // MARK: - Artwork

    /// Artwork for this track (if available)
    public let artwork: Artwork?

    // MARK: - Internal Initializer

    internal init(
        id: UInt64,
        index: Int,
        title: String?,
        artist: String?,
        album: String?,
        genre: String?,
        composer: String?,
        comment: String?,
        grouping: String?,
        location: String?,
        duration: TimeInterval,
        fileSize: UInt64,
        bitrate: UInt32,
        sampleRate: UInt32,
        trackNumber: UInt32,
        totalTracks: UInt32,
        year: UInt32,
        playCount: UInt32,
        skipCount: UInt32,
        rating: Int,
        lastPlayed: Date?,
        lastSkipped: Date?,
        bookmark: TimeInterval?,
        dateAdded: Date?,
        dateModified: Date?,
        artwork: Artwork? = nil
    ) {
        self.id = id
        self.index = index
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.composer = composer
        self.comment = comment
        self.grouping = grouping
        self.location = location
        self.duration = duration
        self.fileSize = fileSize
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.trackNumber = trackNumber
        self.totalTracks = totalTracks
        self.year = year
        self.playCount = playCount
        self.skipCount = skipCount
        self.rating = rating
        self.lastPlayed = lastPlayed
        self.lastSkipped = lastSkipped
        self.bookmark = bookmark
        self.dateAdded = dateAdded
        self.dateModified = dateModified
        self.artwork = artwork
    }
}

// MARK: - Convenience Properties

public extension Track {

    /// Display name - uses title if available, otherwise filename from location
    var displayName: String {
        if let title = title, !title.isEmpty {
            return title
        }
        if let location = location, !location.isEmpty {
            let url = URL(fileURLWithPath: location)
            return url.deletingPathExtension().lastPathComponent
        }
        return "Unknown Track"
    }

    /// Duration formatted as MM:SS or HH:MM:SS
    var durationFormatted: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Whether this track has been played at least once
    var hasBeenPlayed: Bool {
        playCount > 0
    }

    /// Whether this track has been skipped at least once
    var hasBeenSkipped: Bool {
        skipCount > 0
    }

    /// Whether this track has a rating
    var hasRating: Bool {
        rating > 0
    }

    /// Whether this track has a bookmark
    var hasBookmark: Bool {
        bookmark != nil && bookmark! > 0
    }

    /// Play-to-skip ratio (useful for determining track popularity)
    var playToSkipRatio: Double {
        guard skipCount > 0 else { return playCount > 0 ? .infinity : 0 }
        return Double(playCount) / Double(skipCount)
    }

    /// Last played date formatted as a string
    var lastPlayedFormatted: String {
        guard let date = lastPlayed else { return "Never played" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Internal Factory Methods

internal extension Track {

    /// Create a Track from ITDBTrack and optional PlayCountEntry
    static func from(
        _ itdbTrack: ITDBTrack,
        index: Int,
        playCountEntry: PlayCountEntry? = nil,
        artwork: ArtworkImageItem? = nil,
        iPodURL: URL
    ) -> Track {
        // Merge play data - prefer PlayCounts file as it has more recent data
        let playCount = playCountEntry?.playCount ?? itdbTrack.playCount
        let skipCount = playCountEntry?.skipCount ?? 0
        let lastPlayed = playCountEntry?.lastPlayedDate ?? itdbTrack.lastPlayedDate
        let lastSkipped = playCountEntry?.lastSkippedDate
        let rating = playCountEntry.map { Int($0.rating) / 20 } ?? itdbTrack.starRating
        let bookmark = playCountEntry.map { TimeInterval($0.bookmarkTime) / 1000.0 }

        return Track(
            id: itdbTrack.dbid,
            index: index,
            title: itdbTrack.title,
            artist: itdbTrack.artist,
            album: itdbTrack.album,
            genre: itdbTrack.genre,
            composer: itdbTrack.composer,
            comment: itdbTrack.comment,
            grouping: itdbTrack.grouping,
            location: itdbTrack.location,
            duration: itdbTrack.durationInSeconds,
            fileSize: UInt64(itdbTrack.size),
            bitrate: itdbTrack.bitrate,
            sampleRate: itdbTrack.sampleRate,
            trackNumber: itdbTrack.trackNumber,
            totalTracks: itdbTrack.totalTracks,
            year: itdbTrack.year,
            playCount: playCount,
            skipCount: skipCount,
            rating: rating,
            lastPlayed: lastPlayed,
            lastSkipped: lastSkipped,
            bookmark: bookmark,
            dateAdded: nil,
            dateModified: itdbTrack.lastModifiedDate,
            artwork: artwork.map { Artwork(from: $0, iPodURL: iPodURL) }
        )
    }

    /// Create a Track from iTunesSD track and optional iTunesStatEntry
    static func from(
        shuffleTrack: iTunesSDTrack,
        index: Int,
        statEntry: iTunesStatEntry? = nil
    ) -> Track {
        let playCount = statEntry?.playCount ?? 0
        let skipCount = statEntry?.skipCount ?? 0
        let lastPlayed = statEntry?.lastPlayedDate
        let lastSkipped = statEntry?.lastSkippedDate
        let rating = statEntry.map { $0.starRating } ?? 0
        let bookmark = statEntry.map { $0.bookmarkTimeInSeconds }

        // iPod Shuffle doesn't support artwork
        return Track(
            id: UInt64(index),
            index: index,
            title: shuffleTrack.displayName,
            artist: nil,
            album: nil,
            genre: nil,
            composer: nil,
            comment: nil,
            grouping: nil,
            location: shuffleTrack.filename,
            duration: shuffleTrack.durationInSeconds,
            fileSize: 0,
            bitrate: 0,
            sampleRate: 0,
            trackNumber: 0,
            totalTracks: 0,
            year: 0,
            playCount: playCount,
            skipCount: skipCount,
            rating: rating,
            lastPlayed: lastPlayed,
            lastSkipped: lastSkipped,
            bookmark: bookmark,
            dateAdded: nil,
            dateModified: nil,
            artwork: nil
        )
    }

    /// Create a Track from SQLite-based iTunes Library track (newer iPods)
    static func from(_ itLibTrack: ITLibTrack, index: Int, artwork: ArtworkImageItem? = nil, iPodURL: URL) -> Track {
        return Track(
            id: UInt64(bitPattern: itLibTrack.pid),
            index: index,
            title: itLibTrack.title.isEmpty ? nil : itLibTrack.title,
            artist: itLibTrack.artist.isEmpty ? nil : itLibTrack.artist,
            album: itLibTrack.album.isEmpty ? nil : itLibTrack.album,
            genre: nil,
            composer: nil,
            comment: nil,
            grouping: nil,
            location: nil,
            duration: itLibTrack.durationInSeconds,
            fileSize: 0,
            bitrate: 0,
            sampleRate: 0,
            trackNumber: 0,
            totalTracks: 0,
            year: 0,
            playCount: UInt32(itLibTrack.playCount),
            skipCount: 0,
            rating: 0,
            lastPlayed: itLibTrack.lastPlayedDate,
            lastSkipped: nil,
            bookmark: nil,
            dateAdded: nil,
            dateModified: nil,
            artwork: artwork.map { Artwork(from: $0, iPodURL: iPodURL) }
        )
    }
}

// MARK: - Equatable & Hashable

extension Track {
    public static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
