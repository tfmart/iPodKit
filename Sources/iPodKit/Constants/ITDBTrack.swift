//
//  ITDBTrack.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Track Item object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Track_Item
struct ITDBTrack: IPKObject {
    let id: String = "mhit"
}

extension ITDBTrack {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
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
    
    struct Length: IPKField {
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
    
    struct Volume: IPKField {
        var offset: Int { 64 }
        var length: Int { 4 }
    }
    
    struct StartTime: IPKField {
        var offset: Int { 68 }
        var length: Int { 4 }
    }
    
    struct StopTime: IPKField {
        var offset: Int { 72 }
        var length: Int { 4 }
    }
    
    struct SoundCheck: IPKField {
        var offset: Int { 76 }
        var length: Int { 4 }
    }
    
    struct PlayCount: IPKField {
        var offset: Int { 80 }
        var length: Int { 4 }
    }
    
    struct PlayCountUser: IPKField {
        var offset: Int { 84 }
        var length: Int { 4 }
    }
    
    struct LastPlayed: IPKField {
        var offset: Int { 88 }
        var length: Int { 4 }
    }
    
    struct DiskNumber: IPKField {
        var offset: Int { 92 }
        var length: Int { 4 }
    }
    
    struct TotalDisks: IPKField {
        var offset: Int { 96 }
        var length: Int { 4 }
    }
    
    struct UserID: IPKField {
        var offset: Int { 100 }
        var length: Int { 4 }
    }
    
    struct DateAdded: IPKField {
        var offset: Int { 104 }
        var length: Int { 4 }
    }
    
    struct BookmarkTime: IPKField {
        var offset: Int { 108 }
        var length: Int { 4 }
    }
    
    struct DBId: IPKField {
        var offset: Int { 112 }
        var length: Int { 8 }
    }
    
    struct Checked: IPKField {
        var offset: Int { 120 }
        var length: Int { 1 }
    }
    
    struct ApplicationRating: IPKField {
        var offset: Int { 121 }
        var length: Int { 1 }
    }
    
    struct BPM: IPKField {
        var offset: Int { 122 }
        var length: Int { 2 }
    }
    
    struct ArtworkCount: IPKField {
        var offset: Int { 124 }
        var length: Int { 2 }
    }
    
    struct ArtworkSize: IPKField {
        var offset: Int { 126 }
        var length: Int { 2 }
    }
    
    struct CompilationFlag: IPKField {
        var offset: Int { 154 }
        var length: Int { 1 }
    }
    
    struct ArtworkId: IPKField {
        var offset: Int { 200 }
        var length: Int { 4 }
    }
    
    struct Type1: IPKField {
        var offset: Int { 28 }
        var length: Int { 1 }
    }
    
    struct Type2: IPKField {
        var offset: Int { 29 }
        var length: Int { 1 }
    }
    
    struct DateReleased: IPKField {
        var offset: Int { 140 }
        var length: Int { 4 }
    }
    
    struct SampleRate2: IPKField {
        var offset: Int { 136 }
        var length: Int { 4 }
    }
    
    struct SkipCount: IPKField {
        var offset: Int { 156 }
        var length: Int { 4 }
    }
    
    struct LastSkipped: IPKField {
        var offset: Int { 160 }
        var length: Int { 4 }
    }
    
    struct HasArtwork: IPKField {
        var offset: Int { 164 }
        var length: Int { 1 }
    }
    
    struct SkipWhenShuffling: IPKField {
        var offset: Int { 165 }
        var length: Int { 1 }
    }
    
    struct RememberPlaybackPosition: IPKField {
        var offset: Int { 166 }
        var length: Int { 1 }
    }
    
    struct PodcastFlag: IPKField {
        var offset: Int { 167 }
        var length: Int { 1 }
    }
    
    struct DBId2: IPKField {
        var offset: Int { 168 }
        var length: Int { 8 }
    }
    
    struct LyricsFlag: IPKField {
        var offset: Int { 176 }
        var length: Int { 1 }
    }
    
    struct MovieFileFlag: IPKField {
        var offset: Int { 177 }
        var length: Int { 1 }
    }
    
    struct PlayedMark: IPKField {
        var offset: Int { 178 }
        var length: Int { 1 }
    }
    
    struct MediaType: IPKField {
        var offset: Int { 208 }
        var length: Int { 4 }
    }
    
    struct SeasonNumber: IPKField {
        var offset: Int { 212 }
        var length: Int { 4 }
    }
    
    struct EpisodeNumber: IPKField {
        var offset: Int { 216 }
        var length: Int { 4 }
    }
}
