//
//  iTunesDB.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

/// This is the primary database for the iPod. It contains all information about the songs that the iPod is capable of playing, as well as the playlists. It's never written to by the Apple iPod firmware. During an autosync, iTunes completely overwrites this file.
struct iTunesDB: IPKObject {
    let id: String = "mhbd"
    
    struct VersionNumber: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct NumberOfChildren: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
    
    struct Identifier: IPKField {
        var offset: Int { 24 }
        var length: Int { 8 }
    }
    
    struct Language: IPKField {
        var offset: Int { 70 }
        var length: Int { 2 }
    }
}
