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

    /// Disc number in a multi-disc set
    public let discNumber: UInt32

    /// Total number of discs in the set
    public let totalDiscs: UInt32

    /// Beats per minute
    public let bpm: UInt16

    /// Whether this track is part of a compilation album
    public let isCompilation: Bool

    /// The type of media (audio, video, podcast, etc.)
    public let mediaType: MediaType

    /// Volume adjustment (-255 to +255, representing -100% to +100%)
    public let volumeAdjustment: Int32

    /// Start time in milliseconds (custom playback start point)
    public let startTime: UInt32

    /// Stop time in milliseconds (custom playback end point, 0 means play to end)
    public let stopTime: UInt32

    /// SoundCheck value for volume normalization
    public let soundCheck: UInt32

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
        discNumber: UInt32 = 0,
        totalDiscs: UInt32 = 0,
        bpm: UInt16 = 0,
        isCompilation: Bool = false,
        mediaType: MediaType = .audio,
        volumeAdjustment: Int32 = 0,
        startTime: UInt32 = 0,
        stopTime: UInt32 = 0,
        soundCheck: UInt32 = 0,
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
        self.discNumber = discNumber
        self.totalDiscs = totalDiscs
        self.bpm = bpm
        self.isCompilation = isCompilation
        self.mediaType = mediaType
        self.volumeAdjustment = volumeAdjustment
        self.startTime = startTime
        self.stopTime = stopTime
        self.soundCheck = soundCheck
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
            discNumber: itdbTrack.discNumber,
            totalDiscs: itdbTrack.totalDiscs,
            bpm: itdbTrack.bpm,
            isCompilation: itdbTrack.isCompilation,
            mediaType: MediaType(rawValue: itdbTrack.mediaType),
            volumeAdjustment: itdbTrack.volumeAdjustment,
            startTime: itdbTrack.startTime,
            stopTime: itdbTrack.stopTime,
            soundCheck: itdbTrack.soundCheck,
            playCount: playCount,
            skipCount: skipCount,
            rating: rating,
            lastPlayed: lastPlayed,
            lastSkipped: lastSkipped,
            bookmark: bookmark,
            dateAdded: itdbTrack.dateAddedDate,
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

        // iPod Shuffle doesn't support artwork or extended metadata
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
            discNumber: 0,
            totalDiscs: 0,
            bpm: 0,
            isCompilation: false,
            mediaType: .audio,
            volumeAdjustment: 0,
            startTime: 0,
            stopTime: 0,
            soundCheck: 0,
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
            discNumber: 0,
            totalDiscs: 0,
            bpm: 0,
            isCompilation: false,
            mediaType: .audio,
            volumeAdjustment: 0,
            startTime: 0,
            stopTime: 0,
            soundCheck: 0,
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
