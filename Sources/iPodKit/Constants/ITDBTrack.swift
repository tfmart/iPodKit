//
//  ITDBTrack.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

struct ITDBTrack: IPKObject {
    let id: String = "mhit"
}

extension ITDBTrack {
    struct Strings: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct Identifier: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct Visible: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    struct FileType: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
    
    struct Rating: IPKField {
        var offset: Int { 31 }
        var length: Int { 4 }
    }
    
    struct LastModified: IPKField {
        var offset: Int { 32 }
        var length: Int { 8 }
    }
    
    struct Size: IPKField {
        var offset: Int { 36 }
        var length: Int { 8 }
    }
    
    struct Lenght: IPKField {
        var offset: Int { 40 }
        var length: Int { 8 }
    }
    
    struct TrackNumber: IPKField {
        var offset: Int { 44 }
        var length: Int { 8 }
    }
    
    struct TotalTracks: IPKField {
        var offset: Int { 48 }
        var length: Int { 8 }
    }
    
    struct Year: IPKField {
        var offset: Int { 52 }
        var length: Int { 8 }
    }
    
    struct Bitrate: IPKField {
        var offset: Int { 56 }
        var length: Int { 8 }
    }
    
    struct SampleRate: IPKField {
        var offset: Int { 60 }
        var length: Int { 8 }
    }
    
    // MARK: - Resume from http://www.ipodlinux.org/ITunesDB/#Track_Item
}
