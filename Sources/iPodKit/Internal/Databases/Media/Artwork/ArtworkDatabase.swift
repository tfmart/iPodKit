//
//  ArtworkDatabase.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Artwork Database parser for iPod devices.
internal struct ArtworkDatabase: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfChildren: UInt32
    let nextImageId: UInt32
    let imageItems: [ArtworkImageItem]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhfd")

        self.headerLength = try data.readUInt32(at: 4)
        self.totalLength = try data.readUInt32(at: 8)
        self.numberOfChildren = try data.readUInt32(at: 20)
        self.nextImageId = try data.readUInt32(at: 28)

        var imageItems: [ArtworkImageItem] = []
        var offset = Int(headerLength)

        for _ in 0..<numberOfChildren {
            guard offset + 16 <= data.count else { break }

            let childData = data.subdata(in: offset..<data.count)
            guard let childId = try? childData.readString(at: 0, length: 4),
                  childId == "mhsd" else {
                if let sectionLength = try? childData.readUInt32(at: 8) {
                    offset += Int(sectionLength)
                }
                continue
            }

            let mhsdHeaderLength = try childData.readUInt32(at: 4)
            let mhsdTotalLength = try childData.readUInt32(at: 8)
            let mhsdType = try childData.readUInt32(at: 12)

            let innerOffset = Int(mhsdHeaderLength)
            guard innerOffset < childData.count else {
                offset += Int(mhsdTotalLength)
                continue
            }

            let innerData = childData.subdata(in: innerOffset..<childData.count)
            guard innerData.count >= 4 else {
                offset += Int(mhsdTotalLength)
                continue
            }

            let innerId = try innerData.readString(at: 0, length: 4)

            if mhsdType == 1 && innerId == "mhli" {
                imageItems = try Self.parseImageList(from: innerData)
            }

            offset += Int(mhsdTotalLength)
        }

        self.imageItems = imageItems
    }

    private static func parseImageList(from data: Data) throws -> [ArtworkImageItem] {
        guard try data.readString(at: 0, length: 4) == "mhli" else {
            return []
        }

        let headerLength = try data.readUInt32(at: 4)
        let numberOfImages = try data.readUInt32(at: 8)

        var images: [ArtworkImageItem] = []
        var offset = Int(headerLength)

        for _ in 0..<numberOfImages {
            guard offset + 12 <= data.count else { break }

            let imageData = data.subdata(in: offset..<data.count)
            guard let itemId = try? imageData.readString(at: 0, length: 4),
                  itemId == "mhii" else { break }

            let image = try ArtworkImageItem(from: imageData)
            images.append(image)

            offset += Int(image.totalLength)
        }

        return images
    }
}
