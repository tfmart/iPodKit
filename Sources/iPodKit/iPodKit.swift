//
//  iPodKit.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

/// A Swift library for reading iPod databases.
///
/// iPodKit parses iTunes database files and provides a simple interface for
/// accessing track metadata, playlists, and artwork.
///
/// ## Getting Started
///
/// Create an ``iPod`` instance from a supported database file or containing directory:
///
/// ```swift
/// import iPodKit
///
/// let ipod = try iPod(contentsOf: URL(fileURLWithPath: "/Users/me/iPod Database/iTunesDB"))
///
/// print(ipod.deviceName ?? "Unknown iPod")
/// print("Tracks: \(ipod.tracks.count)")
/// print("Playlists: \(ipod.playlists.count)")
///
/// for playlist in ipod.playlists {
///     print("\(playlist.name): \(playlist.tracks.count) tracks")
/// }
/// ```
///
/// ## Supported Formats
///
/// iPodKit automatically detects and parses three database formats:
///
/// - **iTunesDB** — Binary format used by iPod Classic, Mini, and Nano
/// - **iTunesSD** — Binary format used by iPod Shuffle
/// - **iTunes Library (SQLite)** — Used by newer iPod models
///
/// Additional data sources (play counts, artwork, EQ presets) are merged
/// automatically when present.
