//
//  DeviceFilesReader.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// Loads optional device-level files from an iPod volume.
///
/// These files live outside the music databases and describe the device
/// itself: sync source, on-device settings, radio presets, paired Bluetooth
/// devices, and the volume icon. All of them are optional - missing or
/// unreadable files simply produce `nil`/empty values.
internal struct DeviceFilesReader: Sendable {

    let syncSource: SyncSource?
    let settings: DeviceSettings?
    let radioPresets: [RadioPresets]
    let bluetoothDevices: [BluetoothDevice]
    let deviceIconURL: URL?

    init(basePath: String) {
        let base = URL(fileURLWithPath: basePath)
        let fm = FileManager.default

        // Sync source from the binary iTunes prefs file
        let prefsURL = base.appendingPathComponent("iPod_Control/iTunes/iTunesPrefs")
        if let data = try? Data(contentsOf: prefsURL),
           let prefs = iTunesPrefsFile(from: data),
           prefs.userName != nil || prefs.computerName != nil {
            self.syncSource = SyncSource(userName: prefs.userName, computerName: prefs.computerName)
        } else {
            self.syncSource = nil
        }

        // On-device settings
        let settingsURL = base.appendingPathComponent("iPod_Control/Device/iPodSettings.xml")
        if let data = try? Data(contentsOf: settingsURL) {
            self.settings = DeviceSettings(iPodSettingsFile(from: data))
        } else {
            self.settings = nil
        }

        // FM radio presets, one file per region (Presets_US_FM.plist, ...)
        let radioURL = base.appendingPathComponent("iPod_Control/Device/Radio")
        var radio: [RadioPresets] = []
        if let files = try? fm.contentsOfDirectory(atPath: radioURL.path) {
            for file in files.sorted() {
                guard file.hasPrefix("Presets_"), file.hasSuffix(".plist") else { continue }
                let region = file
                    .replacingOccurrences(of: "Presets_", with: "")
                    .replacingOccurrences(of: "_FM.plist", with: "")
                guard let data = try? Data(contentsOf: radioURL.appendingPathComponent(file)),
                      let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                      let presets = RadioPresets(region: region, plist: plist) else { continue }
                radio.append(presets)
            }
        }
        self.radioPresets = radio

        // Paired Bluetooth devices
        let btURL = base.appendingPathComponent("iPod_Control/Device/Bluetooth/btdevices.plist")
        if let data = try? Data(contentsOf: btURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            self.bluetoothDevices = plist
                .compactMap { address, value -> BluetoothDevice? in
                    guard let entry = value as? [String: Any] else { return nil }
                    return BluetoothDevice(address: address, plist: entry)
                }
                .sorted { $0.address < $1.address }
        } else {
            self.bluetoothDevices = []
        }

        // Volume icon written by iTunes, rendering the device model and color
        let iconURL = base.appendingPathComponent(".VolumeIcon.icns")
        self.deviceIconURL = fm.fileExists(atPath: iconURL.path) ? iconURL : nil
    }
}
