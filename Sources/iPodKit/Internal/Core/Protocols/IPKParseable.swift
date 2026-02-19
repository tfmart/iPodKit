//
//  IPKObject.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

internal protocol IPKParseable {
    init(from data: Data) throws
}

extension IPKParseable {
    static func validateMagicNumber(from data: Data, expectedId: String) throws {
        guard data.count >= 4 else {
            throw IPKParsingError.insufficientData
        }

        let magicNumber = try data.readString(at: 0, length: 4)
        guard magicNumber == expectedId else {
            throw IPKParsingError.invalidMagicNumber(expected: expectedId, found: magicNumber)
        }
    }
}
