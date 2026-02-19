//
//  Playlist.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// A unified playlist representation that abstracts away the underlying database format.
///
/// `Playlist` provides a simple, consistent interface for accessing playlist metadata
/// and track references regardless of whether the data comes from a binary iTunesDB
/// or SQLite-based iTunes Library file.
///
/// ## Usage
///
/// ```swift
/// let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))
///
/// for playlist in ipod.playlists {
///     print("\(playlist.displayName) - \(playlist.trackCount) tracks")
/// }
/// ```
///
/// ## Resolving Track References
///
/// Playlists store track references as IDs. To get the actual ``Track`` objects
/// for a playlist, filter the iPod's track array:
///
/// ```swift
/// let playlistTracks = ipod.tracks.filter { playlist.trackIds.contains($0.id) }
/// ```
///
/// > Note: iPod Shuffle does not support playlists. The ``iPod/playlists`` array
/// > will be empty for Shuffle devices.
///
/// ## Topics
///
/// ### Identification
/// - ``id``
/// - ``name``
/// - ``displayName``
///
/// ### Playlist Type
/// - ``isMasterPlaylist``
/// - ``isPodcast``
/// - ``isEmpty``
///
/// ### Track References
/// - ``trackCount``
/// - ``trackIds``
public struct Playlist: Sendable, Identifiable, Hashable {

    // MARK: - Identification

    /// Unique identifier for this playlist.
    public let id: UInt64

    /// Playlist name as stored in the database.
    ///
    /// May be empty for untitled playlists. Use ``displayName`` for a
    /// guaranteed non-empty label.
    public let name: String

    // MARK: - Properties

    /// Whether this is the master playlist containing all tracks on the iPod.
    ///
    /// Every iPod database has exactly one master playlist that references
    /// all tracks. Its ``displayName`` is "All Music".
    public let isMasterPlaylist: Bool

    /// Whether this is a podcast playlist.
    public let isPodcast: Bool

    /// Number of tracks in the playlist.
    public let trackCount: Int

    /// Ordered track IDs belonging to this playlist.
    ///
    /// Each ID corresponds to a ``Track/id``. Use these to look up full
    /// track objects from ``iPod/tracks``:
    ///
    /// ```swift
    /// let playlistTracks = ipod.tracks.filter { playlist.trackIds.contains($0.id) }
    /// ```
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
        trackIds: [UInt64],
        timestamp: Date?
    ) {
        self.id = id
        self.name = name
        self.isMasterPlaylist = isMasterPlaylist
        self.isPodcast = isPodcast
        self.trackCount = trackCount
        self.trackIds = trackIds
        self.timestamp = timestamp
    }
}

// MARK: - Convenience Properties

public extension Playlist {

    /// A human-readable name for display purposes.
    ///
    /// Returns "All Music" for the master playlist, ``name`` for named
    /// playlists, or "Untitled Playlist" when the name is empty.
    var displayName: String {
        if isMasterPlaylist {
            return "All Music"
        }
        return name.isEmpty ? "Untitled Playlist" : name
    }

    /// Whether this playlist has no tracks.
    var isEmpty: Bool {
        trackCount == 0
    }
}

// MARK: - Internal Initializers

internal extension Playlist {

    /// Create a Playlist from an ITDBPlaylist.
    init(_ itdbPlaylist: ITDBPlaylist) {
        let timestamp: Date?
        if itdbPlaylist.timestamp > 0 {
            let macEpochOffset: TimeInterval = 2082844800
            let unixTimestamp = TimeInterval(itdbPlaylist.timestamp) - macEpochOffset
            timestamp = Date(timeIntervalSince1970: unixTimestamp)
        } else {
            timestamp = nil
        }

        self.init(
            id: itdbPlaylist.persistentPlaylistId,
            name: itdbPlaylist.name ?? "",
            isMasterPlaylist: itdbPlaylist.isMasterPlaylist,
            isPodcast: itdbPlaylist.isPodcast,
            trackCount: Int(itdbPlaylist.playlistItemCount),
            trackIds: itdbPlaylist.trackIds.map { UInt64($0) },
            timestamp: timestamp
        )
    }

    /// Create a Playlist from a SQLite-based iTunes Library playlist.
    init(_ itLibPlaylist: ITLibPlaylist) {
        self.init(
            id: UInt64(bitPattern: itLibPlaylist.id),
            name: itLibPlaylist.name,
            isMasterPlaylist: itLibPlaylist.isMasterPlaylist,
            isPodcast: false,
            trackCount: itLibPlaylist.trackPids.count,
            trackIds: itLibPlaylist.trackPids.map { UInt64(bitPattern: $0) },
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
