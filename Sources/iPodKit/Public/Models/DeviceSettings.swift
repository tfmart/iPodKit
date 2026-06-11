//
//  DeviceSettings.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// On-device settings as configured by the user on the iPod itself.
///
/// All values are optional: a setting is `nil` when the device does not store
/// it (older models) or when it was never set.
///
/// ```swift
/// if let settings = ipod.settings {
///     print("Firmware: \(settings.firmwareVersion ?? "unknown")")
///     print("Language: \(settings.language ?? "unknown")")
/// }
/// ```
public struct DeviceSettings: Sendable, Hashable {

    /// How tracks are shuffled during playback.
    public enum ShuffleMode: String, Sendable {
        case off
        case songs
        case albums
    }

    /// How playback repeats.
    public enum RepeatMode: String, Sendable {
        case off
        case one
        case all
    }

    /// Firmware version string (e.g., "1.0.4 (37A40005)").
    public let firmwareVersion: String?

    /// Device UI language identifier (e.g., "en-US").
    public let language: String?

    /// Maximum volume limit (0-255 scale) set on the device or by iTunes.
    public let volumeLimit: Int?

    /// Screen brightness (0-100).
    public let brightness: Int?

    /// Whether the clock uses 24-hour format.
    public let usesTwentyFourHourClock: Bool?

    /// Whether the click wheel / interaction clicker sound is enabled.
    public let clickerEnabled: Bool?

    /// Shuffle mode configured on the device.
    public let shuffleMode: ShuffleMode?

    /// Repeat mode configured on the device.
    public let repeatMode: RepeatMode?

    /// Whether crossfade between songs is enabled.
    public let crossfadeEnabled: Bool?

    /// Whether Sound Check volume normalization is enabled.
    public let soundCheckEnabled: Bool?

    /// Whether VoiceOver is enabled.
    public let voiceOverEnabled: Bool?

    internal init(
        firmwareVersion: String?,
        language: String?,
        volumeLimit: Int?,
        brightness: Int?,
        usesTwentyFourHourClock: Bool?,
        clickerEnabled: Bool?,
        shuffleMode: ShuffleMode?,
        repeatMode: RepeatMode?,
        crossfadeEnabled: Bool?,
        soundCheckEnabled: Bool?,
        voiceOverEnabled: Bool?
    ) {
        self.firmwareVersion = firmwareVersion
        self.language = language
        self.volumeLimit = volumeLimit
        self.brightness = brightness
        self.usesTwentyFourHourClock = usesTwentyFourHourClock
        self.clickerEnabled = clickerEnabled
        self.shuffleMode = shuffleMode
        self.repeatMode = repeatMode
        self.crossfadeEnabled = crossfadeEnabled
        self.soundCheckEnabled = soundCheckEnabled
        self.voiceOverEnabled = voiceOverEnabled
    }

    /// Create settings from a parsed iPodSettings.xml file.
    internal init(_ file: iPodSettingsFile) {
        self.init(
            firmwareVersion: file.string("Settings/SoftwareVersion"),
            language: file.string("General/Language"),
            volumeLimit: file.int("Playback/VolumeLimit"),
            brightness: file.int("General/Brightness"),
            usesTwentyFourHourClock: file.bool("DateTime/TwentyFourHourClock"),
            clickerEnabled: file.bool("General/Clicker"),
            shuffleMode: file.string("Playback/Shuffle").flatMap(ShuffleMode.init(rawValue:)),
            repeatMode: file.string("Playback/Repeat").flatMap(RepeatMode.init(rawValue:)),
            crossfadeEnabled: file.bool("Playback/Crossfade"),
            soundCheckEnabled: file.bool("Playback/SoundCheck"),
            voiceOverEnabled: file.bool("Accessibility/Speech")
        )
    }
}
