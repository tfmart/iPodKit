//
//  iPodDBReader+DatabaseFileType.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

extension iPodDBReader {
    enum DatabaseFileType: String, CaseIterable {
        case iTunesDB = "iTunesDB"
        case playCounts = "Play Counts"
        case otgPlaylist = "OTG Playlist File"
        case equalizerPresets = "Equalizer Presets"
        case artworkDB = "ArtworkDB"
        case photoDB = "Photo Database"
        case iTunesSD = "iTunesSD"
        case iTunesStats = "iTunesStats"
        case iTunesShuffle = "iTunesShuffle"
        case iTunesPState = "iTunesPState"
        
        var standardPaths: [String] {
            switch self {
            case .iTunesDB:
                return ["iPod_Control/iTunes/iTunesDB"]
            case .playCounts:
                return ["iPod_Control/iTunes/Play Counts"]
            case .otgPlaylist:
                return ["iPod_Control/iTunes/OTG Playlist File"]
            case .equalizerPresets:
                return ["iPod_Control/iTunes/Equalizer Presets"]
            case .artworkDB:
                return ["iPod_Control/Artwork/ArtworkDB"]
            case .photoDB:
                return ["Photos/Photo Database"]
            case .iTunesSD:
                return ["iTunesSD"]
            case .iTunesStats:
                return ["iTunesStats"]
            case .iTunesShuffle:
                return ["iTunesShuffle"]
            case .iTunesPState:
                return ["iTunesPState"]
            }
        }

        var fileNames: [String] {
            switch self {
            case .iTunesDB:
                return ["iTunesDB"]
            case .playCounts:
                return ["Play Counts"]
            case .otgPlaylist:
                return ["OTG Playlist File"]
            case .equalizerPresets:
                return ["Equalizer Presets"]
            case .artworkDB:
                return ["ArtworkDB"]
            case .photoDB:
                return ["Photo Database"]
            case .iTunesSD:
                return ["iTunesSD"]
            case .iTunesStats:
                return ["iTunesStats"]
            case .iTunesShuffle:
                return ["iTunesShuffle"]
            case .iTunesPState:
                return ["iTunesPState"]
            }
        }

        init?(url: URL) {
            let fileName = url.lastPathComponent
            guard let type = Self.allCases.first(where: { $0.fileNames.contains(fileName) }) else {
                return nil
            }
            self = type
        }
    }
}
