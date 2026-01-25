//
//  ArtworkThumbnail.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation

/// Represents an mhni (image name/info) record containing thumbnail metadata.
internal struct ArtworkThumbnail: Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfChildren: UInt32
    let correlationId: UInt32
    let ithmbOffset: UInt32
    let imageSize: UInt32
    let verticalPadding: Int16
    let horizontalPadding: Int16
    let imageHeight: UInt16
    let imageWidth: UInt16
    let filename: String?

    init(from data: Data) throws {
        guard data.count >= 4 else {
            throw IPKError.insufficientData
        }

        let magic = try data.readString(at: 0, length: 4)
        guard magic == "mhni" else {
            throw IPKError.invalidMagicNumber(expected: "mhni", found: magic)
        }

        self.headerLength = try data.readUInt32(at: 4)
        self.totalLength = try data.readUInt32(at: 8)
        self.numberOfChildren = try data.readUInt32(at: 12)
        self.correlationId = try data.readUInt32(at: 16)
        self.ithmbOffset = try data.readUInt32(at: 20)
        self.imageSize = try data.readUInt32(at: 24)
        self.verticalPadding = try data.readInt16(at: 28)
        self.horizontalPadding = try data.readInt16(at: 30)
        self.imageHeight = try data.readUInt16(at: 32)
        self.imageWidth = try data.readUInt16(at: 34)

        var parsedFilename: String? = nil
        if numberOfChildren > 0 {
            let childOffset = Int(headerLength)
            if childOffset + 24 <= data.count {
                let childData = data.subdata(in: childOffset..<data.count)
                if let childId = try? childData.readString(at: 0, length: 4), childId == "mhod" {
                    let mhodType = try childData.readUInt16(at: 12)
                    if mhodType == 3 {
                        let stringLength = try childData.readUInt32(at: 24)
                        if stringLength > 0 && 28 + Int(stringLength) <= childData.count {
                            let stringData = childData.subdata(in: 28..<28 + Int(stringLength))
                            if let str = String(data: stringData, encoding: .utf16LittleEndian) {
                                parsedFilename = str.trimmingCharacters(in: .init(charactersIn: "\0"))
                            }
                        }
                    }
                }
            }
        }
        self.filename = parsedFilename
    }

    var ithmbFilename: String {
        "F\(correlationId)_1.ithmb"
    }

    var pixelCount: Int {
        Int(imageWidth) * Int(imageHeight)
    }
}
