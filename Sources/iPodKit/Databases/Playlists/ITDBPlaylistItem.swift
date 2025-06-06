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
struct ITDBPlaylistItem: IPKObject {
    let id: String = "mhip"
}

extension ITDBPlaylistItem {
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
    
    struct PodcastGroupingFlag: IPKField {
        var offset: Int { 16 }
        var length: Int { 2 }
    }
    
    struct Unknown4: IPKField {
        var offset: Int { 18 }
        var length: Int { 1 }
    }
    
    struct Unknown5: IPKField {
        var offset: Int { 19 }
        var length: Int { 1 }
    }
    
    struct GroupId: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    struct TrackId: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
    
    struct Timestamp: IPKField {
        var offset: Int { 28 }
        var length: Int { 4 }
    }
    
    struct PodcastGroupingReference: IPKField {
        var offset: Int { 32 }
        var length: Int { 4 }
    }
}