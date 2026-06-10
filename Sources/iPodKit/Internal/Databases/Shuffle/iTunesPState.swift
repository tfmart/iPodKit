//
//  iTunesPState.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// iTunesPState File parser for iPod Shuffle devices
/// 
/// The iTunesPState file tracks the current playback state of iPod Shuffle
/// including volume, position, shuffle mode, and current track.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#iTunesPState
internal struct iTunesPState: IPKParseable, Sendable {
    // Binary fields (little-endian)
    let volume: UInt32
    let position: UInt32
    let currentTrack: UInt32
    let shuffleMode: UInt32
    let repeatMode: UInt32
    let isPlaying: UInt32
    let soundCheck: UInt32
    let remainingTime: UInt32
    
    init(from data: Data) throws {
        guard data.count >= 32 else {
            throw IPKParsingError.insufficientData
        }
        
        // Read binary fields (little-endian)
        self.volume = try data.readUInt32(at: 0)
        self.position = try data.readUInt32(at: 4)
        self.currentTrack = try data.readUInt32(at: 8)
        self.shuffleMode = try data.readUInt32(at: 12)
        self.repeatMode = try data.readUInt32(at: 16)
        self.isPlaying = try data.readUInt32(at: 20)
        self.soundCheck = try data.readUInt32(at: 24)
        self.remainingTime = try data.readUInt32(at: 28)
    }
}

// MARK: - Convenience Properties
extension iTunesPState {
    /// Volume as percentage (0-100)
    var volumePercentage: Int {
        return min(100, Int((Double(volume) / 255.0) * 100))
    }
    
    /// Position in current track in seconds
    var positionInSeconds: Double {
        return Double(position) / 1000.0
    }
    
    /// Position formatted as MM:SS
    var positionFormatted: String {
        let totalSeconds = Int(positionInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Remaining time in seconds
    var remainingTimeInSeconds: Double {
        return Double(remainingTime) / 1000.0
    }
    
    /// Remaining time formatted as MM:SS
    var remainingTimeFormatted: String {
        let totalSeconds = Int(remainingTimeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Whether currently playing
    var isCurrentlyPlaying: Bool {
        return isPlaying != 0
    }
    
    /// Whether sound check is enabled
    var isSoundCheckEnabled: Bool {
        return soundCheck != 0
    }
    
    /// Shuffle mode description
    var shuffleModeDescription: String {
        switch shuffleMode {
        case 0: return "Off"
        case 1: return "Songs"
        case 2: return "Albums"
        default: return "Unknown (\(shuffleMode))"
        }
    }
    
    /// Repeat mode description
    var repeatModeDescription: String {
        switch repeatMode {
        case 0: return "Off"
        case 1: return "One"
        case 2: return "All"
        default: return "Unknown (\(repeatMode))"
        }
    }
    
    /// Progress through current track as percentage (0-100)
    var progressPercentage: Double {
        guard remainingTime > 0 else { return 0 }
        let totalTime = position + remainingTime
        guard totalTime > 0 else { return 0 }
        return (Double(position) / Double(totalTime)) * 100.0
    }
    
    /// Total track time in seconds
    var totalTrackTime: Double {
        return positionInSeconds + remainingTimeInSeconds
    }
    
    /// Total track time formatted as MM:SS
    var totalTrackTimeFormatted: String {
        let totalSeconds = Int(totalTrackTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Internal API
extension iTunesPState {
    /// Create a summary dictionary of the playback state
    var summary: [String: Any] {
        return [
            "currentTrack": currentTrack,
            "position": positionFormatted,
            "remainingTime": remainingTimeFormatted,
            "totalTime": totalTrackTimeFormatted,
            "progress": String(format: "%.1f%%", progressPercentage),
            "volume": "\(volumePercentage)%",
            "isPlaying": isCurrentlyPlaying,
            "shuffleMode": shuffleModeDescription,
            "repeatMode": repeatModeDescription,
            "soundCheck": isSoundCheckEnabled
        ]
    }
}