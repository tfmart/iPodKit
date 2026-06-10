//
//  PhotoImageList.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

internal struct PhotoImageList: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfImages: UInt32
    let images: [PhotoImage]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhli")
        
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.numberOfImages = try Self.numberOfImagesField.readUInt32(from: data)
        
        var images: [PhotoImage] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfImages {
            guard offset < data.count else { break }
            
            let imageData = data.subdata(in: offset..<data.count)
            let image = try PhotoImage(from: imageData)
            images.append(image)
            
            offset += Int(image.totalLength)
        }
        
        self.images = images
    }
}

extension PhotoImageList {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let numberOfImagesField = IPKBinaryField(offset: 12, length: 4)
}
