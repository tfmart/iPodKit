//
//  IPKError.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

public enum IPKError: Error, Sendable {
    case invalidOffset(Int)
    case invalidString
    case invalidMagicNumber(expected: String, found: String)
    case insufficientData
    case corruptedData
    case fieldSizeMismatch(expected: Int, actual: Int, field: String)
}

extension IPKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidOffset(let offset):
            return "Invalid offset: \(offset)"
        case .invalidString:
            return "Failed to decode string"
        case .invalidMagicNumber(let expected, let found):
            return "Invalid magic number. Expected '\(expected)', found '\(found)'"
        case .insufficientData:
            return "Insufficient data for parsing"
        case .corruptedData:
            return "Data appears to be corrupted"
        case .fieldSizeMismatch(let expected, let actual, let field):
            return "Field size mismatch in \(field): expected \(expected) bytes, got \(actual) bytes"
        }
    }
}