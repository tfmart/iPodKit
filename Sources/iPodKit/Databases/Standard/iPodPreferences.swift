//
//  iPodPreferences.swift
//  iPodKit
//
//  Created by Tomas Martins on 17/02/26.
//

import Foundation

/// Minimal parser for the iPod Preferences file (`/iPod_Control/Device/Preferences`).
///
/// Currently only extracts the device timezone byte at offset 0xB10 (2832).
/// The encoding is: subtract 0x19 (UTC+0 baseline), divide by 2 for hours,
/// modulo 2 for the DST flag (1 = active, add 1 hour).
struct iPodPreferences: Sendable {
    let deviceTimeZone: TimeZone?

    init(from data: Data) {
        guard data.count > 2832 else {
            self.deviceTimeZone = nil
            return
        }
        let raw = data[2832]
        // 0x00 means the timezone field was never populated by iTunes
        guard raw != 0 else {
            self.deviceTimeZone = nil
            return
        }
        let adjusted = Int(raw) - 0x19
        let hours = adjusted / 2
        let dstActive = adjusted % 2 == 1
        let totalSeconds = (hours + (dstActive ? 1 : 0)) * 3600
        self.deviceTimeZone = TimeZone(secondsFromGMT: totalSeconds)
    }
}
