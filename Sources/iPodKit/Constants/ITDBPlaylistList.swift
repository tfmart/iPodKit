//
//  ITDBPlaylistList.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Playlist List object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Playlist_List
struct ITDBPlaylistList: IPKObject {
    let id: String = "mhlp"
}

extension ITDBPlaylistList {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct NumberOfPlaylists: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
}
