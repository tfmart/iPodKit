//
//  DTOs.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation
import iPodKit

// JSON output types for the CLI. These define the tool's stable machine-readable
// schema, decoupled from the library's models:
// - ids are decimal strings (UInt64 dbids exceed 2^53 and would be corrupted by
//   double-based JSON consumers)
// - dates are ISO8601 UTC, durations are seconds

// MARK: - Track

package struct TrackDTO: Encodable, Sendable {
    package let id: String
    package let title: String?
    package let artist: String?
    package let album: String?
    package let genre: String?
    package let composer: String?
    package let comment: String?
    package let grouping: String?
    package let location: String?
    package let duration: Double
    package let fileSize: Int
    package let bitrate: Int?
    package let sampleRate: Int?
    package let trackNumber: Int?
    package let totalTracks: Int?
    package let year: Int?
    package let discNumber: Int?
    package let totalDiscs: Int?
    package let bpm: Int?
    package let isCompilation: Bool
    package let mediaType: String
    package let volumeAdjustment: Int
    package let startTime: Double?
    package let stopTime: Double?
    package let soundCheck: Int?
    package let playCount: Int
    package let skipCount: Int
    package let rating: Int
    package let lastPlayed: Date?
    package let lastSkipped: Date?
    package let bookmark: Double?
    package let dateAdded: Date?
    package let dateModified: Date?
    package let artwork: ArtworkInfoDTO?

    package init(_ track: Track) {
        self.id = String(track.id)
        self.title = track.title
        self.artist = track.artist
        self.album = track.album
        self.genre = track.genre
        self.composer = track.composer
        self.comment = track.comment
        self.grouping = track.grouping
        self.location = track.location
        self.duration = track.duration
        self.fileSize = track.fileSize
        self.bitrate = track.bitrate
        self.sampleRate = track.sampleRate
        self.trackNumber = track.trackNumber
        self.totalTracks = track.totalTracks
        self.year = track.year
        self.discNumber = track.discNumber
        self.totalDiscs = track.totalDiscs
        self.bpm = track.bpm
        self.isCompilation = track.isCompilation
        self.mediaType = Self.mediaTypeName(track.mediaType)
        self.volumeAdjustment = track.volumeAdjustment
        self.startTime = track.startTime
        self.stopTime = track.stopTime
        self.soundCheck = track.soundCheck
        self.playCount = track.playCount
        self.skipCount = track.skipCount
        self.rating = track.rating
        self.lastPlayed = track.lastPlayed
        self.lastSkipped = track.lastSkipped
        self.bookmark = track.bookmark
        self.dateAdded = track.dateAdded
        self.dateModified = track.dateModified
        self.artwork = track.artwork.map(ArtworkInfoDTO.init)
    }

    // Stable schema values derived from case names, not displayName (which is
    // user-facing and free to change).
    private static func mediaTypeName(_ type: MediaType) -> String {
        switch type {
        case .audio: return "audio"
        case .video: return "video"
        case .podcast: return "podcast"
        case .videoPodcast: return "videoPodcast"
        case .audiobook: return "audiobook"
        case .musicVideo: return "musicVideo"
        case .tvShow: return "tvShow"
        case .tvShowWithMusic: return "tvShowWithMusic"
        case .unknown: return "unknown"
        }
    }
}

// MARK: - Playlist

package struct PlaylistDTO: Encodable, Sendable {
    package let id: String
    package let name: String
    package let isMasterPlaylist: Bool
    package let isPodcast: Bool
    package let trackCount: Int
    package let trackIds: [String]
    package let timestamp: Date?

    package init(_ playlist: Playlist) {
        self.id = String(playlist.id)
        self.name = playlist.name
        self.isMasterPlaylist = playlist.isMasterPlaylist
        self.isPodcast = playlist.isPodcast
        self.trackCount = playlist.trackCount
        self.trackIds = playlist.trackIds.map(String.init)
        self.timestamp = playlist.timestamp
    }
}

// MARK: - Device Info

package struct InfoDTO: Encodable, Sendable {
    package let path: String
    package let deviceName: String?
    package let serialNumber: String?
    package let firmwareVersion: String?
    package let trackCount: Int
    package let playlistCount: Int
    package let tracksWithArtwork: Int

    package init(_ ipod: iPod) {
        self.path = ipod.url.path
        self.deviceName = ipod.deviceName
        self.serialNumber = ipod.serialNumber
        self.firmwareVersion = ipod.settings?.firmwareVersion
        self.trackCount = ipod.tracks.count
        self.playlistCount = ipod.playlists.count
        // count(where:) requires a newer stdlib than the macOS 10.15 floor
        self.tracksWithArtwork = ipod.tracks.lazy.filter { $0.artwork != nil }.count
    }
}

// MARK: - Device Detail

package struct DeviceDTO: Encodable, Sendable {

    package struct SyncSourceDTO: Encodable, Sendable {
        package let userName: String?
        package let computerName: String?

        package init(_ source: SyncSource) {
            self.userName = source.userName
            self.computerName = source.computerName
        }
    }

    package struct SettingsDTO: Encodable, Sendable {
        package let firmwareVersion: String?
        package let language: String?
        package let volumeLimit: Int?
        package let brightness: Int?
        package let usesTwentyFourHourClock: Bool?
        package let clickerEnabled: Bool?
        package let shuffleMode: String?
        package let repeatMode: String?
        package let crossfadeEnabled: Bool?
        package let soundCheckEnabled: Bool?
        package let voiceOverEnabled: Bool?

        package init(_ settings: DeviceSettings) {
            self.firmwareVersion = settings.firmwareVersion
            self.language = settings.language
            self.volumeLimit = settings.volumeLimit
            self.brightness = settings.brightness
            self.usesTwentyFourHourClock = settings.usesTwentyFourHourClock
            self.clickerEnabled = settings.clickerEnabled
            self.shuffleMode = settings.shuffleMode?.rawValue
            self.repeatMode = settings.repeatMode?.rawValue
            self.crossfadeEnabled = settings.crossfadeEnabled
            self.soundCheckEnabled = settings.soundCheckEnabled
            self.voiceOverEnabled = settings.voiceOverEnabled
        }
    }

    package struct RadioPresetsDTO: Encodable, Sendable {
        package let region: String
        package let lastStation: Double?
        package let presets: [Double]

        package init(_ radio: RadioPresets) {
            self.region = radio.region
            self.lastStation = radio.lastStation
            self.presets = radio.presets
        }
    }

    package struct BluetoothDeviceDTO: Encodable, Sendable {
        package let address: String
        package let name: String?
        package let supportsAudio: Bool
        package let supportsRemoteControl: Bool

        package init(_ device: BluetoothDevice) {
            self.address = device.address
            self.name = device.name
            self.supportsAudio = device.supportsAudio
            self.supportsRemoteControl = device.supportsRemoteControl
        }
    }

    package let name: String?
    package let serialNumber: String?
    package let deviceIconPath: String?
    package let syncSource: SyncSourceDTO?
    package let settings: SettingsDTO?
    package let radioPresets: [RadioPresetsDTO]
    package let bluetoothDevices: [BluetoothDeviceDTO]

    package init(_ ipod: iPod) {
        self.name = ipod.deviceName
        self.serialNumber = ipod.serialNumber
        self.deviceIconPath = ipod.deviceIconURL?.path
        self.syncSource = ipod.syncSource.map(SyncSourceDTO.init)
        self.settings = ipod.settings.map(SettingsDTO.init)
        self.radioPresets = ipod.radioPresets.map(RadioPresetsDTO.init)
        self.bluetoothDevices = ipod.bluetoothDevices.map(BluetoothDeviceDTO.init)
    }
}

// MARK: - Artwork

package struct ArtworkInfoDTO: Encodable, Sendable {
    package struct SizeDTO: Encodable, Sendable {
        package let width: Int
        package let height: Int
    }

    package let sizes: [SizeDTO]

    package init(_ artwork: Artwork) {
        self.sizes = artwork.sizes.map { SizeDTO(width: $0.width, height: $0.height) }
    }
}

package struct ArtworkExportDTO: Encodable, Sendable {
    package let path: String
    package let width: Int
    package let height: Int

    package init(path: String, width: Int, height: Int) {
        self.path = path
        self.width = width
        self.height = height
    }
}
