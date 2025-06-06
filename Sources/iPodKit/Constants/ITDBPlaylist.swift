//
//  ITDBPlaylist.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Playlist object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Playlist
struct ITDBPlaylist: IPKObject {
    let id: String = "mhyp"
}

extension ITDBPlaylist {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct DataObjectChildCount: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct PlaylistItemCount: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct IsMasterPlaylistFlag: IPKField {
        var offset: Int { 20 }
        var length: Int { 1 }
    }
    
    struct Unknown: IPKField {
        var offset: Int { 21 }
        var length: Int { 3 }
    }
    
    struct Timestamp: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
    
    struct PersistentPlaylistId: IPKField {
        var offset: Int { 28 }
        var length: Int { 8 }
    }
    
    struct Unknown3: IPKField {
        var offset: Int { 36 }
        var length: Int { 4 }
    }
    
    struct StringMHODCount: IPKField {
        var offset: Int { 40 }
        var length: Int { 2 }
    }
    
    struct PodcastFlag: IPKField {
        var offset: Int { 42 }
        var length: Int { 2 }
    }
    
    struct ListSortOrder: IPKField {
        var offset: Int { 44 }
        var length: Int { 4 }
    }
}