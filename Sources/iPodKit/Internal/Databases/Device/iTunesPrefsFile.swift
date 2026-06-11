//
//  iTunesPrefsFile.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// Parser for the binary iTunes preferences file (`iPod_Control/iTunes/iTunesPrefs`).
///
/// The file starts with the magic `frpd` and contains two fixed-width,
/// NUL-padded UTF-8 string fields identifying the iTunes library the iPod
/// last synced with: the library owner's user name and the computer name.
internal struct iTunesPrefsFile: Sendable {
    let userName: String?
    let computerName: String?

    private static let magic = "frpd"
    private static let userNameField = (offset: 0x180, length: 64)
    private static let computerNameField = (offset: 0x1C0, length: 64)

    init?(from data: Data) {
        guard data.count >= 4,
              String(data: data.prefix(4), encoding: .ascii) == Self.magic else {
            return nil
        }

        self.userName = Self.paddedString(in: data, at: Self.userNameField)
        self.computerName = Self.paddedString(in: data, at: Self.computerNameField)
    }

    /// Read a NUL-padded UTF-8 string from a fixed-width field.
    private static func paddedString(in data: Data, at field: (offset: Int, length: Int)) -> String? {
        guard data.count >= field.offset + field.length else { return nil }
        var bytes = data.subdata(in: field.offset..<(field.offset + field.length))
        if let nulIndex = bytes.firstIndex(of: 0) {
            bytes = bytes.prefix(upTo: nulIndex)
        }
        guard !bytes.isEmpty, let string = String(data: bytes, encoding: .utf8) else { return nil }
        return string
    }
}
