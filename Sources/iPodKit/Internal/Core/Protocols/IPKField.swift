//
//  File.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

internal protocol IPKField {
    var offset: Int { get }
    var length: Int { get }
}

extension IPKField {
    func readUInt8(from data: Data) throws -> UInt8 {
        guard length == 1 else {
            throw IPKParsingError.fieldSizeMismatch(expected: 1, actual: length, field: "\(type(of: self))")
        }
        return try data.readUInt8(at: offset)
    }
    
    func readUInt16(from data: Data) throws -> UInt16 {
        guard length == 2 else {
            throw IPKParsingError.fieldSizeMismatch(expected: 2, actual: length, field: "\(type(of: self))")
        }
        return try data.readUInt16(at: offset)
    }
    
    func readUInt32(from data: Data) throws -> UInt32 {
        guard length == 4 else {
            throw IPKParsingError.fieldSizeMismatch(expected: 4, actual: length, field: "\(type(of: self))")
        }
        return try data.readUInt32(at: offset)
    }

    func readInt32(from data: Data) throws -> Int32 {
        guard length == 4 else {
            throw IPKParsingError.fieldSizeMismatch(expected: 4, actual: length, field: "\(type(of: self))")
        }
        return try data.readInt32(at: offset)
    }

    func readUInt64(from data: Data) throws -> UInt64 {
        guard length == 8 else {
            throw IPKParsingError.fieldSizeMismatch(expected: 8, actual: length, field: "\(type(of: self))")
        }
        return try data.readUInt64(at: offset)
    }
    
    func readBytes(from data: Data) throws -> Data {
        return try data.readBytes(at: offset, length: length)
    }
}
