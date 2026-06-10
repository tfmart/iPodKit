//
//  ITDBDataObject+TypeIdentifier.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

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
        case composer = 12
        case grouping = 13
        case description = 14
        case podcastEnclosureURL = 15
        case podcastRSSURL = 16
        case chapterData = 17
        case subtitle = 18
        case show = 19
        case episodeNumber = 20
        case tvNetwork = 21
        case albumArtist = 22
        case sortArtist = 23
        case keywords = 24
        case tvShowLocale = 25
        case sortTitle = 27
        case sortAlbum = 28
        case sortAlbumArtist = 29
        case sortComposer = 30
        case sortTVShow = 31
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
                 .description, .podcastEnclosureURL, .podcastRSSURL,
                 .subtitle, .show, .episodeNumber, .tvNetwork, .albumArtist,
                 .sortArtist, .keywords, .tvShowLocale, .sortTitle, .sortAlbum,
                 .sortAlbumArtist, .sortComposer, .sortTVShow:
                return true
            default:
                return false
            }
        }

        var usesInlineStringLength: Bool {
            switch self {
            case .podcastEnclosureURL, .podcastRSSURL:
                return false
            default:
                return isStringType
            }
        }

    }
}
