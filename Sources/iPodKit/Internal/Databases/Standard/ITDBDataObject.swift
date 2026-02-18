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
struct ITDBDataObject: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let type: TypeIdentifier
    let stringValue: String?

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhod")

        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)

        let typeRaw = try Self.DataType().readUInt32(from: data)
        self.type = TypeIdentifier(rawValue: typeRaw) ?? .unknown

        _ = try Self.Position().readUInt32(from: data)
        
        // Parse string data if this is a string type
        if self.type.isStringType {
            let stringDataLength = Int(totalLength) - Int(headerLength)
            if stringDataLength > 0 {
                let stringOffset = Int(headerLength)
                self.stringValue = try data.readMHODString(at: stringOffset, length: stringDataLength)
            } else {
                self.stringValue = ""
            }
        } else {
            self.stringValue = nil
        }
    }
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
    
    struct Position: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
}

extension ITDBDataObject {
    enum TypeIdentifier: UInt32, CaseIterable {
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
        case unknown = 999999
        
        var isStringType: Bool {
            switch self {
            case .title, .location, .album, .artist, .genre, .filetype, 
                 .eqSetting, .comment, .category, .composer, .grouping, 
                 .description, .podcastEnclosureURL, .podcastRSSURL:
                return true
            default:
                return false
            }
        }
        
        var name: String {
            switch self {
            case .title: return "Title"
            case .location: return "Location"
            case .album: return "Album" 
            case .artist: return "Artist"
            case .genre: return "Genre"
            case .filetype: return "File Type"
            case .eqSetting: return "EQ Setting"
            case .comment: return "Comment"
            case .category: return "Category"
            case .composer: return "Composer"
            case .grouping: return "Grouping"
            case .description: return "Description"
            case .podcastEnclosureURL: return "Podcast Enclosure URL"
            case .podcastRSSURL: return "Podcast RSS URL"
            case .chapterData: return "Chapter Data"
            case .smartPlaylistData: return "Smart Playlist Data"
            case .smartPlaylistRules: return "Smart Playlist Rules"
            case .libraryPlaylistIndex: return "Library Playlist Index"
            case .letterJumpTable: return "Letter Jump Table"
            case .playlistColumnDefinition: return "Playlist Column Definition"
            case .unknown: return "Unknown"
            }
        }
    }
}