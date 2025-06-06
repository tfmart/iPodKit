//
//  ITDBTrackList.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

/// TrackList object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#TrackList
struct ITDBTrackList: IPKObject {
    let id: String = "mhlt"
}

extension ITDBTrackList {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct NumberOfSongs: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
}
