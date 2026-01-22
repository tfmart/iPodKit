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
public struct iTunesDBDataSet: IPKParseable {
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let type: UInt32
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhsd")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.type = try Self.TypeField().readUInt32(from: data)
    }
    
    func getType(from data: Data) throws -> UInt32 {
        return try Self.TypeField().readUInt32(from: data)
    }
    
    func getTotalLength(from data: Data) throws -> UInt32 {
        return try Self.TotalLength().readUInt32(from: data)
    }
}

extension iTunesDBDataSet {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct TypeField: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}
