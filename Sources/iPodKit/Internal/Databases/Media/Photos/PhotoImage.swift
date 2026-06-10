//
//  PhotoImage.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

internal struct PhotoImage: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let imageId: UInt32
    let originalDate: UInt32
    let imageSize: UInt32
    let fileName: String?
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhii")
        
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.imageId = try Self.imageIdField.readUInt32(from: data)
        self.originalDate = try Self.originalDateField.readUInt32(from: data)
        self.imageSize = try Self.imageSizeField.readUInt32(from: data)
        
        // Try to read filename if there's more data
        if Int(headerLength) < data.count {
            let nameData = data.subdata(in: Int(headerLength)..<data.count)
            self.fileName = try? nameData.readMHODString(at: 0, length: nameData.count)
        } else {
            self.fileName = nil
        }
    }
}

extension PhotoImage {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let imageIdField = IPKBinaryField(offset: 12, length: 4)
    static let originalDateField = IPKBinaryField(offset: 16, length: 4)
    static let imageSizeField = IPKBinaryField(offset: 20, length: 4)
}
