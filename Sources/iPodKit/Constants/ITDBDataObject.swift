//
//  ITDBDataObject.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Data Object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Data_Object
struct ITDBDataObject: IPKObject {
    let id: String = "mhod"
}

extension ITDBDataObject {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct DataType: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct Unknown1: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct Unknown2: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    struct Position: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
}

extension ITDBDataObject {
    enum TypeIdentifier: UInt32 {
        case title = 1
        case location = 2
        case album = 3
        case artist = 4
        case genre = 5
        case filetype = 6
        case eqSetting = 7
        case comment = 8
        case category = 9
        case composer = 10
        case grouping = 11
        case description = 12
        case podcastEnclosureURL = 13
        case podcastRSSURL = 14
        case chapterData = 17
        case smartPlaylistData = 50
        case smartPlaylistRules = 51
        case libraryPlaylistIndex = 52
        case letterJumpTable = 53
        case playlistColumnDefinition = 100
    }
}