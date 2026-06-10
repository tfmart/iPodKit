//
//  iTunesDBDataSet.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

/// DataSet object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#DataSet
internal struct iTunesDBDataSet: IPKParseable {
    let headerLength: UInt32
    let totalLength: UInt32
    let type: UInt32
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhsd")
        
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.type = try Self.typeFieldField.readUInt32(from: data)
    }
    
    func getType(from data: Data) throws -> UInt32 {
        return try Self.typeFieldField.readUInt32(from: data)
    }
    
    func getTotalLength(from data: Data) throws -> UInt32 {
        return try Self.totalLengthField.readUInt32(from: data)
    }
}

extension iTunesDBDataSet {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let typeFieldField = IPKBinaryField(offset: 12, length: 4)
}
