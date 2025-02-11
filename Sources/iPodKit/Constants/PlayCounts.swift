//
//  PlayCounts.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

struct PlayCounts {
    let id: String = "mhdp"
    
    //MARK: - Header
    let fileHeaderLenght: Int = 96
    let headerLastOffset: Int = 4
}

// MARK: - Entry Fields
extension PlayCounts {
    /// The play count header indicates a valid play count file and specifies how many entries follow and the size of each entry record.
    /// The is an entry record for each song on the iPod; the entry position corresponding to the position of the song in the iTunesDB.
    struct Header: IPKField {
        var offset: Int { 4 }
        var length: Int { 96 }
    }
    
    /// The number of played times since last sync
    struct Entry: IPKField {
        var offset: Int { 0 }
        var length: Int { 4 }
    }
    
    /// Last played time. Set to zero in older firmwares, or to the value from iTunesDB in newer ones (anything with the "Music" menu).
    struct LastPlayed: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
     /// Position in file that the song was last paused/stopped at, in milliseconds. This works for audiobooks, podcasts, and seemingly anything else with the right bit set in the MHIT (unk19).
    struct AudioBookmark: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    /// Rating given to song. Number of stars (1-5) `*0x14`. Set to zero in older firmwares, or to the value from iTunesDB in newer ones (anything with the "Music" menu).
    struct Rating: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    /// Number of times skipped since last sync. This field appears with firmware that supports the 0x13 version iTunesDB.
    struct SkipCount: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    /// Last skipped date/time. Set to zero if never skipped. This field appears with firmware that supports the 0x13 version iTunesDB.
    struct LastSkipped: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }
}
