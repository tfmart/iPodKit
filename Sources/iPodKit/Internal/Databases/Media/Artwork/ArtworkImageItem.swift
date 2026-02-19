//
//  ArtworkImageItem.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation

/// Represents an mhii (image item) record in the ArtworkDB.
internal struct ArtworkImageItem: Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfChildren: UInt32
    let imageId: UInt32
    let songId: UInt64
    let rating: UInt32
    let originalDate: UInt32
    let digitizedDate: UInt32
    let sourceImageSize: UInt32
    let thumbnails: [ArtworkThumbnail]

    init(from data: Data) throws {
        guard data.count >= 4 else {
            throw IPKParsingError.insufficientData
        }

        let magic = try data.readString(at: 0, length: 4)
        guard magic == "mhii" else {
            throw IPKParsingError.invalidMagicNumber(expected: "mhii", found: magic)
        }

        self.headerLength = try data.readUInt32(at: 4)
        self.totalLength = try data.readUInt32(at: 8)
        self.numberOfChildren = try data.readUInt32(at: 12)
        self.imageId = try data.readUInt32(at: 16)
        self.songId = try data.readUInt64(at: 20)
        self.rating = try data.readUInt32(at: 32)
        self.originalDate = try data.readUInt32(at: 40)
        self.digitizedDate = try data.readUInt32(at: 44)
        self.sourceImageSize = try data.readUInt32(at: 48)

        var thumbnails: [ArtworkThumbnail] = []
        var offset = Int(headerLength)

        for _ in 0..<numberOfChildren {
            guard offset + 12 <= data.count else { break }

            let childData = data.subdata(in: offset..<min(offset + Int(totalLength) - offset, data.count))
            guard childData.count >= 4 else { break }

            let childId = try childData.readString(at: 0, length: 4)

            if childId == "mhod" {
                let mhodHeaderLength = try childData.readUInt32(at: 4)
                let mhodTotalLength = try childData.readUInt32(at: 8)
                let mhodType = try childData.readUInt16(at: 12)

                if mhodType == 2 {
                    let mhniOffset = Int(mhodHeaderLength)
                    if mhniOffset < childData.count {
                        let mhniData = childData.subdata(in: mhniOffset..<childData.count)
                        if let mhniId = try? mhniData.readString(at: 0, length: 4), mhniId == "mhni" {
                            let thumbnail = try ArtworkThumbnail(from: mhniData)
                            thumbnails.append(thumbnail)
                        }
                    }
                }

                offset += Int(mhodTotalLength)
            } else {
                if let childLength = try? childData.readUInt32(at: 8) {
                    offset += Int(childLength)
                } else {
                    break
                }
            }
        }

        self.thumbnails = thumbnails
    }
}
