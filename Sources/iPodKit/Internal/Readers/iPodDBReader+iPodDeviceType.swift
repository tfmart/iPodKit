//
//  iPodDBReader+iPodDeviceType.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

extension iPodDBReader {
    enum iPodDeviceType {
        case standard       // Regular iPod with iTunesDB
        case shuffle        // iPod Shuffle with iTunesSD
        case photo          // iPod Photo with artwork support
        case sqliteLibrary  // Newer iPods with SQLite-based iTunes Library
        case unknown

        var supportedFiles: [String] {
            switch self {
            case .standard:
                return ["iTunesDB", "Play Counts", "OTG Playlist File", "Equalizer Presets"]
            case .shuffle:
                return ["iTunesSD", "iTunesStats", "iTunesShuffle", "iTunesPState"]
            case .photo:
                return ["iTunesDB", "Play Counts", "OTG Playlist File", "ArtworkDB", "Photo Database"]
            case .sqliteLibrary:
                return ["Library.itdb", "Dynamic.itdb", "Locations.itdb", "Genius.itdb", "Extras.itdb"]
            case .unknown:
                return []
            }
        }
    }
}
