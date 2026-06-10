//
//  ITDBDataObject.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Data Object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Data_Object
internal struct ITDBDataObject: IPKParseable, Sendable {
    let headerLength: UInt32
    let totalLength: UInt32
    let type: TypeIdentifier
    let stringValue: String?

    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhod")

        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)

        let typeRaw = try Self.dataTypeField.readUInt32(from: data)
        self.type = TypeIdentifier(rawValue: typeRaw) ?? .unknown

        _ = try Self.positionField.readUInt32(from: data)
        
        self.stringValue = try Self.parseStringValue(type: type, headerLength: headerLength, totalLength: totalLength, data: data)
    }

    private static func parseStringValue(
        type: TypeIdentifier,
        headerLength: UInt32,
        totalLength: UInt32,
        data: Data
    ) throws -> String? {
        guard type.isStringType else {
            return nil
        }

        let totalLength = min(Int(totalLength), data.count)

        if type.usesInlineStringLength {
            let stringOffset = 40
            guard stringOffset <= totalLength else {
                throw IPKParsingError.insufficientData
            }

            let declaredLength = Int(try Self.stringLengthField.readUInt32(from: data))
            let availableLength = totalLength - stringOffset
            let stringLength = min(declaredLength, availableLength)

            guard stringLength > 0 else {
                return ""
            }

            return try data.readMHODString(at: stringOffset, length: stringLength)
        }

        let stringOffset = Int(headerLength)
        guard stringOffset <= totalLength else {
            throw IPKParsingError.insufficientData
        }

        let stringLength = totalLength - stringOffset
        guard stringLength > 0 else {
            return ""
        }

        return try data.readUTF8String(at: stringOffset, length: stringLength)
    }
}

extension ITDBDataObject {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let dataTypeField = IPKBinaryField(offset: 12, length: 4)
    static let positionField = IPKBinaryField(offset: 24, length: 4)
    static let stringLengthField = IPKBinaryField(offset: 28, length: 4)
}
