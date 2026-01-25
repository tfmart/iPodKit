//
//  ArtworkFileItem.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation

/// Represents an mhif (file) record in the ArtworkDB file list.
internal struct ArtworkFileItem: Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let correlationId: UInt32
    let imageSize: UInt32

    init(from data: Data) throws {
        guard data.count >= 4 else {
            throw IPKError.insufficientData
        }

        let magic = try data.readString(at: 0, length: 4)
        guard magic == "mhif" else {
            throw IPKError.invalidMagicNumber(expected: "mhif", found: magic)
        }

        self.headerLength = try data.readUInt32(at: 4)
        self.totalLength = try data.readUInt32(at: 8)
        self.correlationId = try data.readUInt32(at: 16)
        self.imageSize = try data.readUInt32(at: 20)
    }
}
