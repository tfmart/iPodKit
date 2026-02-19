//
//  iPodKit.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

/// A Swift library for reading iPod databases.
///
/// iPodKit parses iTunes database files from mounted iPod devices and provides
/// a simple, unified interface for accessing track metadata, playlists, and artwork.
///
/// ## Getting Started
///
/// Create an ``iPod`` instance by pointing it at the root directory of a mounted iPod:
///
/// ```swift
/// import iPodKit
///
/// let ipod = try iPod(url: URL(fileURLWithPath: "/Volumes/iPod"))
///
/// print(ipod.deviceName ?? "Unknown iPod")
/// print("Tracks: \(ipod.tracks.count)")
/// print("Playlists: \(ipod.playlists.count)")
///
/// for track in ipod.tracks {
///     print("\(track.title ?? "Unknown") - \(track.artist ?? "Unknown")")
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
