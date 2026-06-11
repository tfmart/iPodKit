//
//  BluetoothDevice.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// A Bluetooth device paired with the iPod.
///
/// Available on iPods with Bluetooth support (e.g., iPod nano 7th generation).
///
/// ```swift
/// for device in ipod.bluetoothDevices {
///     print("\(device.name ?? device.address) - audio: \(device.supportsAudio)")
/// }
/// ```
public struct BluetoothDevice: Sendable, Hashable, Identifiable {

    /// Bluetooth MAC address (e.g., "08:FF:44:08:2F:13").
    public let address: String

    /// Device name as advertised when last seen (e.g., "John's AirPods Pro").
    public let name: String?

    /// Whether the device supports audio streaming (A2DP).
    public let supportsAudio: Bool

    /// Whether the device supports remote control (AVRCP).
    public let supportsRemoteControl: Bool

    public var id: String { address }

    internal init(address: String, name: String?, supportsAudio: Bool, supportsRemoteControl: Bool) {
        self.address = address
        self.name = name
        self.supportsAudio = supportsAudio
        self.supportsRemoteControl = supportsRemoteControl
    }

    /// Create from one entry of `btdevices.plist`.
    internal init(address: String, plist: [String: Any]) {
        self.init(
            address: address,
            name: (plist["Name"] as? String) ?? (plist["DefaultName"] as? String),
            supportsAudio: (plist["ServiceA2DP"] as? String) == "Supported",
            supportsRemoteControl: (plist["ServiceRemote"] as? String) == "Supported"
        )
    }
}
