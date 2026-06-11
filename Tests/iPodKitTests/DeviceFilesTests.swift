//
//  DeviceFilesTests.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Testing
import Foundation
@testable import iPodKit

// MARK: - iTunesPrefs (frpd)

private func makePrefsData(userName: String?, computerName: String?) -> Data {
    var data = Data(count: 0x200)
    data.replaceSubrange(0..<4, with: "frpd".data(using: .ascii)!)
    if let userName {
        let bytes = userName.data(using: .utf8)!
        data.replaceSubrange(0x180..<(0x180 + bytes.count), with: bytes)
    }
    if let computerName {
        let bytes = computerName.data(using: .utf8)!
        data.replaceSubrange(0x1C0..<(0x1C0 + bytes.count), with: bytes)
    }
    return data
}

@Test func testITunesPrefsParsesNames() {
    let data = makePrefsData(userName: "Tomas Martins", computerName: "Tomas’s MacBook Pro")
    let prefs = iTunesPrefsFile(from: data)
    #expect(prefs?.userName == "Tomas Martins")
    #expect(prefs?.computerName == "Tomas’s MacBook Pro")
}

@Test func testITunesPrefsRejectsWrongMagic() {
    var data = makePrefsData(userName: "User", computerName: "Computer")
    data.replaceSubrange(0..<4, with: "mhbd".data(using: .ascii)!)
    #expect(iTunesPrefsFile(from: data) == nil)
}

@Test func testITunesPrefsEmptyFieldsAreNil() {
    let data = makePrefsData(userName: nil, computerName: nil)
    let prefs = iTunesPrefsFile(from: data)
    #expect(prefs?.userName == nil)
    #expect(prefs?.computerName == nil)
}

@Test func testITunesPrefsTooShortDataIsSafe() {
    let data = "frpd".data(using: .ascii)!
    let prefs = iTunesPrefsFile(from: data)
    #expect(prefs?.userName == nil)
    #expect(prefs?.computerName == nil)
}

// MARK: - iPodSettings.xml

private let settingsXML = """
<iPodSettings version="1.0"><Settings><SoftwareVersion>1.0.4 (37A40005)</SoftwareVersion></Settings>\
<General><BacklightTimer>10</BacklightTimer><Brightness>40</Brightness><Clicker>on</Clicker>\
<Language>en-US</Language></General>\
<Playback><Crossfade>0</Crossfade><SoundCheck>0</SoundCheck><VolumeLimit>232</VolumeLimit>\
<Repeat>off</Repeat><Shuffle>songs</Shuffle></Playback>\
<DateTime><TwentyFourHourClock>1</TwentyFourHourClock><TimeZone>58</TimeZone></DateTime>\
<Accessibility><Speech>0</Speech></Accessibility></iPodSettings>
"""

@Test func testDeviceSettingsFromXML() {
    let file = iPodSettingsFile(from: settingsXML.data(using: .utf8)!)
    let settings = DeviceSettings(file)

    #expect(settings.firmwareVersion == "1.0.4 (37A40005)")
    #expect(settings.language == "en-US")
    #expect(settings.volumeLimit == 232)
    #expect(settings.brightness == 40)
    #expect(settings.usesTwentyFourHourClock == true)
    #expect(settings.clickerEnabled == true)
    #expect(settings.shuffleMode == .songs)
    #expect(settings.repeatMode == .off)
    #expect(settings.crossfadeEnabled == false)
    #expect(settings.soundCheckEnabled == false)
    #expect(settings.voiceOverEnabled == false)
}

@Test func testDeviceSettingsMissingValuesAreNil() {
    let file = iPodSettingsFile(from: "<iPodSettings/>".data(using: .utf8)!)
    let settings = DeviceSettings(file)
    #expect(settings.firmwareVersion == nil)
    #expect(settings.shuffleMode == nil)
    #expect(settings.volumeLimit == nil)
}

// MARK: - Radio Presets

@Test func testRadioPresetsFrequencyConversion() {
    let plist: [String: Any] = [
        "Band": 2,
        "LastStation": 875000,
        "Presets": [1013000, 905000],
        "Region": 1,
        "Version": 1,
    ]
    let presets = RadioPresets(region: "US", plist: plist)
    #expect(presets?.region == "US")
    #expect(presets?.lastStation == 87.5)
    #expect(presets?.presets == [101.3, 90.5])
}

@Test func testRadioPresetsZeroStationIsNil() {
    let presets = RadioPresets(region: "EU", plist: ["LastStation": 0, "Presets": []])
    #expect(presets?.lastStation == nil)
    #expect(presets?.presets.isEmpty == true)
}

// MARK: - Bluetooth Devices

@Test func testBluetoothDeviceFromPlist() {
    let entry: [String: Any] = [
        "DefaultName": "Headphones",
        "Name": "AirPods Pro",
        "ServiceA2DP": "Supported",
        "ServiceRemote": "Supported",
        "ServiceSensor": "Unsupported",
    ]
    let device = BluetoothDevice(address: "F8:73:DF:E8:2F:4F", plist: entry)
    #expect(device.address == "F8:73:DF:E8:2F:4F")
    #expect(device.name == "AirPods Pro")
    #expect(device.supportsAudio == true)
    #expect(device.supportsRemoteControl == true)
    #expect(device.id == "F8:73:DF:E8:2F:4F")
}

@Test func testBluetoothDeviceFallsBackToDefaultName() {
    let device = BluetoothDevice(address: "AA:BB:CC:DD:EE:FF", plist: ["DefaultName": "Speaker"])
    #expect(device.name == "Speaker")
    #expect(device.supportsAudio == false)
}

// MARK: - Serial Number Registry Lookup

@Test func testSerialLookupExactAndFuzzyMatch() throws {
    let registry: [String: Any] = [
        "Devices": [
            "000A2700267C5416": [
                "Device Class": "iPod",
                "Serial Number": "DCYLV2VBF0GT",
            ],
            "000A1DE81EF8C01E": [
                "Device Class": "iPhone",
                "Serial Number": "SHOULDNOTMATCH",
            ],
        ]
    ]
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ipodkit-test-registry-\(UUID().uuidString).plist")
    let data = try PropertyListSerialization.data(fromPropertyList: registry, format: .binary, options: 0)
    try data.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    // Exact GUID match
    #expect(DeviceSerialResolver.appleSerialNumber(forUSBSerial: "000A2700267C5416", registryURL: url) == "DCYLV2VBF0GT")
    // Fuzzy match: USB exposes a GUID variant differing in the middle
    #expect(DeviceSerialResolver.appleSerialNumber(forUSBSerial: "000A2700247C5416", registryURL: url) == "DCYLV2VBF0GT")
    // No match
    #expect(DeviceSerialResolver.appleSerialNumber(forUSBSerial: "FFFFFFFFFFFFFFFF", registryURL: url) == nil)
}
