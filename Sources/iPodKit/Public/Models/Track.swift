//
//  Track.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// A media item stored in an iPod library.
///
/// ## Overview
///
/// Use `Track` values from ``iPod/tracks`` or ``Playlist/tracks`` to display
/// music metadata, playback information, and artwork.
///
/// ```swift
/// let ipod = try iPod(contentsOf: databaseURL)
///
/// for track in ipod.tracks {
///     let title = track.title ?? "Unknown Title"
///     let artist = track.artist ?? "Unknown Artist"
///
///     print("\(title) by \(artist)")
///     print("Played \(track.playCount) times")
/// }
/// ```
///
/// Use ``id`` when you need stable identity, such as diffing tracks between
/// snapshots or matching a track to ``Playlist/trackIds``.
///
/// Load artwork through ``artwork`` when it is available:
///
/// ```swift
/// if let artwork = track.artwork {
///     let image = try await artwork.image()
///     print("Artwork size: \(image.width)x\(image.height)")
/// }
/// ```
///
/// ## Topics
///
/// ### Identification
/// - ``id``
///
/// ### Track Metadata
/// - ``title``
/// - ``artist``
/// - ``album``
/// - ``genre``
/// - ``composer``
/// - ``comment``
/// - ``grouping``
/// - ``location``
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
/// - ``trackNumber``
/// - ``totalTracks``
/// - ``year``
/// - ``discNumber``
/// - ``totalDiscs``
/// - ``bpm``
/// - ``mediaType``
///
/// ### Artwork
/// - ``artwork``
public struct Track: Sendable, Identifiable, Hashable {

    // MARK: - Identification

    /// Unique identifier for this track.
    public let id: UInt64

    /// Internal index used for cross-referencing with play counts.
    internal let index: Int

    // MARK: - Metadata

    /// Track title.
    public let title: String?

    /// Artist name.
    public let artist: String?

    /// Album name.
    public let album: String?

    /// Genre.
    public let genre: String?

    /// Composer.
    public let composer: String?

    /// Comment or description.
    public let comment: String?

    /// Track grouping.
    public let grouping: String?

    /// File path on the iPod.
    public let location: String?

    // MARK: - Audio Properties

    /// Track duration in seconds.
    public let duration: TimeInterval

    /// File size in bytes.
    public let fileSize: Int

    /// Audio bitrate in kbps, or `nil` if not available.
    public let bitrate: Int?

    /// Sample rate in Hz, or `nil` if not available.
    public let sampleRate: Int?

    /// Track number on the album, or `nil` if not set.
    public let trackNumber: Int?

    /// Total tracks on the album, or `nil` if not set.
    public let totalTracks: Int?

    /// Release year, or `nil` if not set.
    public let year: Int?

    /// Disc number in a multi-disc set, or `nil` if not set.
    public let discNumber: Int?

    /// Total number of discs in the set, or `nil` if not set.
    public let totalDiscs: Int?

    /// Beats per minute, or `nil` if not set.
    public let bpm: Int?

    /// Whether this track is part of a compilation album.
    public let isCompilation: Bool

    /// The type of media (audio, video, podcast, etc.).
    public let mediaType: MediaType

    /// Volume adjustment (-255 to +255, representing -100% to +100%).
    public let volumeAdjustment: Int

    /// Custom playback start point in seconds, or `nil` if not set.
    public let startTime: TimeInterval?

    /// Custom playback end point in seconds, or `nil` if not set.
    public let stopTime: TimeInterval?

    /// SoundCheck value for volume normalization, or `nil` if not set.
    public let soundCheck: Int?

    // MARK: - User Data

    /// Number of times the track has been played.
    public let playCount: Int

    /// Number of times the track has been skipped.
    public let skipCount: Int

    /// Star rating (0-5).
    public let rating: Int

    /// Date the track was last played.
    public let lastPlayed: Date?

    /// Date the track was last skipped.
    public let lastSkipped: Date?

    /// Bookmark position in seconds (for resumable playback).
    public let bookmark: TimeInterval?

    /// Date the track was added to the library.
    public let dateAdded: Date?

    /// Date the track was last modified.
    public let dateModified: Date?

    // MARK: - Artwork

    /// Artwork for this track, if available.
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
        fileSize: Int,
        bitrate: Int?,
        sampleRate: Int?,
        trackNumber: Int?,
        totalTracks: Int?,
        year: Int?,
        discNumber: Int? = nil,
        totalDiscs: Int? = nil,
        bpm: Int? = nil,
        isCompilation: Bool = false,
        mediaType: MediaType = .audio,
        volumeAdjustment: Int = 0,
        startTime: TimeInterval? = nil,
        stopTime: TimeInterval? = nil,
        soundCheck: Int? = nil,
        playCount: Int,
        skipCount: Int,
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

// MARK: - Internal Initializers

internal extension Track {

    /// Zero-to-nil helper for numeric fields where 0 means "not available".
    private static func nonZero(_ value: UInt32) -> Int? {
        value == 0 ? nil : Int(value)
    }

    private static func nonZero(_ value: UInt16) -> Int? {
        value == 0 ? nil : Int(value)
    }

    /// Milliseconds to optional TimeInterval (nil if zero).
    private static func msToSeconds(_ ms: UInt32) -> TimeInterval? {
        ms == 0 ? nil : TimeInterval(ms) / 1000.0
    }

    /// Create a Track from an ITDBTrack and optional PlayCountEntry.
    init(
        _ itdbTrack: ITDBTrack,
        index: Int,
        playCountEntry: PlayCountEntry? = nil,
        artwork: ArtworkImageItem? = nil,
        iPodURL: URL
    ) {
        // Merge play data - prefer PlayCounts file as it has more recent data
        let playCount = playCountEntry?.playCount ?? itdbTrack.playCount
        let skipCount = playCountEntry?.skipCount ?? 0
        let lastPlayed = playCountEntry?.lastPlayedDate ?? itdbTrack.lastPlayedDate
        let lastSkipped = playCountEntry?.lastSkippedDate
        let rating = playCountEntry.map { Int($0.rating) / 20 } ?? itdbTrack.starRating
        let bookmark = playCountEntry.map { TimeInterval($0.bookmarkTime) / 1000.0 }

        self.init(
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
            fileSize: Int(itdbTrack.size),
            bitrate: Self.nonZero(itdbTrack.bitrate),
            sampleRate: Self.nonZero(itdbTrack.sampleRate),
            trackNumber: Self.nonZero(itdbTrack.trackNumber),
            totalTracks: Self.nonZero(itdbTrack.totalTracks),
            year: Self.nonZero(itdbTrack.year),
            discNumber: Self.nonZero(itdbTrack.discNumber),
            totalDiscs: Self.nonZero(itdbTrack.totalDiscs),
            bpm: Self.nonZero(itdbTrack.bpm),
            isCompilation: itdbTrack.isCompilation,
            mediaType: MediaType(rawValue: itdbTrack.mediaType),
            volumeAdjustment: Int(itdbTrack.volumeAdjustment),
            startTime: Self.msToSeconds(itdbTrack.startTime),
            stopTime: Self.msToSeconds(itdbTrack.stopTime),
            soundCheck: Self.nonZero(itdbTrack.soundCheck),
            playCount: Int(playCount),
            skipCount: Int(skipCount),
            rating: rating,
            lastPlayed: lastPlayed,
            lastSkipped: lastSkipped,
            bookmark: bookmark,
            dateAdded: itdbTrack.dateAddedDate,
            dateModified: itdbTrack.lastModifiedDate,
            artwork: artwork.map { Artwork(from: $0, iPodURL: iPodURL) }
        )
    }

    /// Create a Track from an iTunesSD track and optional iTunesStatEntry.
    init(
        shuffleTrack: iTunesSDTrack,
        index: Int,
        statEntry: iTunesStatEntry? = nil
    ) {
        let playCount = statEntry?.playCount ?? 0
        let skipCount = statEntry?.skipCount ?? 0
        let lastPlayed = statEntry?.lastPlayedDate
        let lastSkipped = statEntry?.lastSkippedDate
        let rating = statEntry.map { $0.starRating } ?? 0
        let bookmark = statEntry.map { $0.bookmarkTimeInSeconds }

        self.init(
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
            bitrate: nil,
            sampleRate: nil,
            trackNumber: nil,
            totalTracks: nil,
            year: nil,
            playCount: Int(playCount),
            skipCount: Int(skipCount),
            rating: rating,
            lastPlayed: lastPlayed,
            lastSkipped: lastSkipped,
            bookmark: bookmark,
            dateAdded: nil,
            dateModified: nil
        )
    }

    /// Create a Track from an iTunes Library track.
    init(_ itLibTrack: ITLibTrack, index: Int, artwork: ArtworkImageItem? = nil, iPodURL: URL) {
        self.init(
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
            bitrate: nil,
            sampleRate: nil,
            trackNumber: nil,
            totalTracks: nil,
            year: nil,
            playCount: itLibTrack.playCount,
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
