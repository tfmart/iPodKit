//
//  IPKParsingError.swift
//  iPodKit
//

import Foundation

internal enum IPKParsingError: Error, Sendable {
    case invalidOffset(Int)
    case invalidString
    case invalidMagicNumber(expected: String, found: String)
    case insufficientData
    case fieldSizeMismatch(expected: Int, actual: Int, field: String)
    case fileNotFound(String)
    case databaseError(String)
}

extension IPKParsingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidOffset(let offset):
            return "Invalid offset: \(offset)"
        case .invalidString:
            return "Failed to decode string"
        case .invalidMagicNumber(let expected, let found):
            return "Invalid magic number. Expected '\(expected)', found '\(found)'"
        case .insufficientData:
            return "Insufficient data for parsing"
        case .fieldSizeMismatch(let expected, let actual, let field):
            return "Field size mismatch in \(field): expected \(expected) bytes, got \(actual) bytes"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
