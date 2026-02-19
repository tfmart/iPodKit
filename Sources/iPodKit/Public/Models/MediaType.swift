//
//  MediaType.swift
//  iPodKit
//
//  Created by Claude on 25/01/26.
//

import Foundation

/// The type of media content for a track.
///
/// Media type determines how the track appears in iPod menus and what
/// playback features are available.
public enum MediaType: UInt32, Sendable, CaseIterable {
    /// Audio file (music)
    case audio = 0x00000001

    /// Video file (movie)
    case video = 0x00000002

    /// Podcast episode
    case podcast = 0x00000004

    /// Video podcast episode
    case videoPodcast = 0x00000006

    /// Audiobook
    case audiobook = 0x00000008

    /// Music video
    case musicVideo = 0x00000020

    /// TV Show (appears only in TV Shows menu)
    case tvShow = 0x00000040

    /// TV Show (appears in both TV Shows and Music menus)
    case tvShowWithMusic = 0x00000060

    /// Unknown or unspecified media type (could be audio or video)
    case unknown = 0x00000000

    /// Initialize from a raw value, defaulting to unknown for unrecognized values
    public init(rawValue: UInt32) {
        switch rawValue {
        case 0x00000001: self = .audio
        case 0x00000002: self = .video
        case 0x00000004: self = .podcast
        case 0x00000006: self = .videoPodcast
        case 0x00000008: self = .audiobook
        case 0x00000020: self = .musicVideo
        case 0x00000040: self = .tvShow
        case 0x00000060: self = .tvShowWithMusic
        default: self = .unknown
        }
    }
    
    /// Human-readable description of the media type
    var displayName: String {
        switch self {
        case .audio: return "Music"
        case .video: return "Movie"
        case .podcast: return "Podcast"
        case .videoPodcast: return "Video Podcast"
        case .audiobook: return "Audiobook"
        case .musicVideo: return "Music Video"
        case .tvShow, .tvShowWithMusic: return "TV Show"
        case .unknown: return "Unknown"
        }
    }
}
