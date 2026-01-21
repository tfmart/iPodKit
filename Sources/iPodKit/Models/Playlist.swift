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
/// and track references regardless of the underlying iPod database format.
///
/// ## Usage
///
/// ```swift
/// let ipod = try iPod(path: "/Volumes/iPod")
///
/// for playlist in ipod.playlists {
///     print("\(playlist.name) - \(playlist.trackCount) tracks")
/// }
/// ```
public struct Playlist: Sendable, Identifiable, Hashable {

    // MARK: - Identification

    /// Unique identifier for this playlist
    public let id: UInt64

    /// Playlist name
    public let name: String

    // MARK: - Properties

    /// Whether this is the master playlist containing all tracks
    public let isMasterPlaylist: Bool

    /// Whether this is a podcast playlist
    public let isPodcast: Bool

    /// Number of tracks in the playlist
    public let trackCount: Int

    /// Track IDs in this playlist (in order)
    public let trackIds: [UInt64]

    /// Date the playlist was created or last modified
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

    /// Display name for the playlist
    var displayName: String {
        if isMasterPlaylist {
            return "All Music"
        }
        return name.isEmpty ? "Untitled Playlist" : name
    }

    /// Whether this playlist has any tracks
    var isEmpty: Bool {
        trackCount == 0
    }
}

// MARK: - Internal Factory Methods

internal extension Playlist {

    /// Create a Playlist from ITDBPlaylist
    static func from(_ itdbPlaylist: ITDBPlaylist) -> Playlist {
        let timestamp: Date?
        if itdbPlaylist.timestamp > 0 {
            let macEpochOffset: TimeInterval = 2082844800
            let unixTimestamp = TimeInterval(itdbPlaylist.timestamp) - macEpochOffset
            timestamp = Date(timeIntervalSince1970: unixTimestamp)
        } else {
            timestamp = nil
        }

        // Convert track IDs from UInt32 to UInt64
        let trackIds = itdbPlaylist.trackIds.map { UInt64($0) }

        return Playlist(
            id: itdbPlaylist.persistentPlaylistId,
            name: itdbPlaylist.name ?? "",
            isMasterPlaylist: itdbPlaylist.isMasterPlaylist,
            isPodcast: itdbPlaylist.isPodcast,
            trackCount: Int(itdbPlaylist.playlistItemCount),
            trackIds: trackIds,
            timestamp: timestamp
        )
    }

    /// Create a Playlist from SQLite-based iTunes Library container
    static func from(
        id: UInt64,
        name: String,
        trackIds: [UInt64],
        isMasterPlaylist: Bool = false
    ) -> Playlist {
        return Playlist(
            id: id,
            name: name,
            isMasterPlaylist: isMasterPlaylist,
            isPodcast: false,
            trackCount: trackIds.count,
            trackIds: trackIds,
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
