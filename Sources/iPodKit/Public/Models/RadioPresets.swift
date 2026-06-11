//
//  RadioPresets.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// FM radio state for one tuner region (e.g., US or EU).
///
/// iPods with an FM radio store the saved presets and the last-tuned station
/// per region.
///
/// ```swift
/// for radio in ipod.radioPresets {
///     print("\(radio.region): last tuned to \(radio.lastStation ?? 0) MHz")
/// }
/// ```
public struct RadioPresets: Sendable, Hashable {

    /// Tuner region identifier from the device (e.g., "US", "EU").
    public let region: String

    /// The last station the radio was tuned to, in MHz (e.g., 87.5).
    public let lastStation: Double?

    /// Saved preset stations, in MHz.
    public let presets: [Double]

    internal init(region: String, lastStation: Double?, presets: [Double]) {
        self.region = region
        self.lastStation = lastStation
        self.presets = presets
    }

    /// Create from a `Presets_<REGION>_FM.plist` file's contents.
    internal init?(region: String, plist: [String: Any]) {
        // Frequencies are stored as Hz * 100 / 10 kHz units (875000 == 87.5 MHz).
        func mhz(_ value: Any?) -> Double? {
            guard let raw = value as? Int, raw > 0 else { return nil }
            return Double(raw) / 10000.0
        }

        self.region = region
        self.lastStation = mhz(plist["LastStation"])
        self.presets = (plist["Presets"] as? [Any])?.compactMap(mhz) ?? []
    }
}
