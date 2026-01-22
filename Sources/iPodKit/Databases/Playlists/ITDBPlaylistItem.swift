//
//  ITDBPlaylistItem.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Playlist Item object in iTunes database
///
/// Reference: http://www.ipodlinux.org/ITunesDB/#Playlist_Item
enum ITDBPlaylistItem {
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }

    struct TrackId: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
}