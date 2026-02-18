//
//  PhotoImageList.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

struct PhotoImageList: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfImages: UInt32
    let images: [PhotoImage]

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhli")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfImages = try Self.NumberOfImages().readUInt32(from: data)
        
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
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfImages: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}
