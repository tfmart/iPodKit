//
//  PlayCounts.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

/// This is the return information file for the iPod. It contains all information that is available to change via the iPod, with regards to the song. When you autosync, iTunes reads this file and updates the iTunes database accordingly. After it does this, it erases this file, so as to prevent it from duplicating data by mistake. The iPod will create this file on playback if it is not there.
struct PlayCounts: IPKObject {
    let id: String = "mhdp"
}

// MARK: - Entry Fields
extension PlayCounts {
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
