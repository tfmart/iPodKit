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
internal enum ITDBPlaylistItem {}

extension ITDBPlaylistItem {
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let trackIdField = IPKBinaryField(offset: 24, length: 4)
}
