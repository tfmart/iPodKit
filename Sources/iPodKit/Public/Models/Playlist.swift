//
//  Playlist.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// An ordered collection of tracks stored on an iPod.
///
/// ## Overview
///
/// Use ``iPod/playlists`` to access playlists loaded from the iPod. Each
/// playlist contains resolved ``tracks`` in playlist order, so most apps can
/// iterate the tracks directly.
///
/// ```swift
/// let ipod = try iPod(contentsOf: databaseURL)
///
/// for playlist in ipod.playlists {
///     print("\(playlist.name): \(playlist.tracks.count) tracks")
///
///     for track in playlist.tracks {
///         print(track.title ?? "Unknown Title")
///     }
/// }
/// ```
///
/// The master playlist represents the full music library. Use
/// ``isMasterPlaylist`` when you want to find it:
///
/// ```swift
/// let library = ipod.playlists.first(where: \.isMasterPlaylist)
/// ```
///
/// Use ``trackIds`` only when you need the raw relationship stored by the
/// database. If the loaded database doesn't include playlist records,
/// ``iPod/playlists`` is empty.
///
/// ## Topics
///
/// ### Identification
/// - ``id``
/// - ``name``
///
/// ### Playlist Type
/// - ``isMasterPlaylist``
/// - ``isPodcast``
///
/// ### Track References
/// - ``trackCount``
/// - ``tracks``
/// - ``trackIds``
/// - ``timestamp``
public struct Playlist: Sendable, Identifiable, Hashable {

    // MARK: - Identification

    /// Unique identifier for this playlist.
    public let id: UInt64

    /// A human-readable playlist name.
    public let name: String

    // MARK: - Properties

    /// Whether this is the master playlist containing all tracks on the iPod.
    ///
    /// Every iPod database has exactly one master playlist that references
    /// all tracks. Its ``name`` is "All Music".
    public let isMasterPlaylist: Bool

    /// Whether this is a podcast playlist.
    public let isPodcast: Bool

    /// Number of tracks in the playlist.
    public let trackCount: Int

    /// Ordered tracks belonging to this playlist.
    ///
    /// These are resolved when the playlist is created by ``iPod``. The array
    /// is empty for empty playlists.
    public let tracks: [Track]

    /// Ordered identifiers for the tracks belonging to this playlist.
    ///
    /// Each ID corresponds to a ``Track/id`` in ``tracks``.
    public let trackIds: [UInt64]

    /// Date the playlist was created or last modified, if available.
    public let timestamp: Date?

    // MARK: - Internal Initializer

    internal init(
        id: UInt64,
        name: String,
        isMasterPlaylist: Bool,
        isPodcast: Bool,
        trackCount: Int,
        tracks: [Track] = [],
        trackIds: [UInt64],
        timestamp: Date?
    ) {
        self.id = id
        self.name = Self.normalizedName(name, isMasterPlaylist: isMasterPlaylist)
        self.isMasterPlaylist = isMasterPlaylist
        self.isPodcast = isPodcast
        self.trackCount = trackCount
        self.tracks = tracks
        self.trackIds = trackIds
        self.timestamp = timestamp
    }
}

// MARK: - Private Helpers

private extension Playlist {

    static func normalizedName(_ name: String, isMasterPlaylist: Bool) -> String {
        if isMasterPlaylist {
            return "All Music"
        }

        return name.isEmpty ? "Untitled Playlist" : name
    }
}

// MARK: - Internal Initializers

internal extension Playlist {

    /// Create a Playlist from an ITDBPlaylist.
    init(_ itdbPlaylist: ITDBPlaylist, tracks: [Track]? = nil) {
        let timestamp: Date?
        if itdbPlaylist.timestamp > 0 {
            let macEpochOffset: TimeInterval = 2082844800
            let unixTimestamp = TimeInterval(itdbPlaylist.timestamp) - macEpochOffset
            timestamp = Date(timeIntervalSince1970: unixTimestamp)
        } else {
            timestamp = nil
        }

        let resolvedTracks = tracks ?? []
        self.init(
            id: itdbPlaylist.persistentPlaylistId,
            name: itdbPlaylist.name ?? "",
            isMasterPlaylist: itdbPlaylist.isMasterPlaylist,
            isPodcast: itdbPlaylist.isPodcast,
            trackCount: tracks?.count ?? Int(itdbPlaylist.playlistItemCount),
            tracks: resolvedTracks,
            trackIds: tracks?.map(\.id) ?? itdbPlaylist.trackIds.map { UInt64($0) },
            timestamp: timestamp
        )
    }

    /// Create a Playlist from an iTunes Library playlist.
    init(_ itLibPlaylist: ITLibPlaylist, tracks: [Track]? = nil) {
        let resolvedTracks = tracks ?? []
        self.init(
            id: UInt64(bitPattern: itLibPlaylist.id),
            name: itLibPlaylist.name,
            isMasterPlaylist: itLibPlaylist.isMasterPlaylist,
            isPodcast: false,
            trackCount: tracks?.count ?? itLibPlaylist.trackPids.count,
            tracks: resolvedTracks,
            trackIds: tracks?.map(\.id) ?? itLibPlaylist.trackPids.map { UInt64(bitPattern: $0) },
            timestamp: nil
        )
    }
}

// MARK: - Equatable & Hashable

extension Playlist {
    public static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
