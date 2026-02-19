//
//  IPKError.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Errors thrown by iPodKit.
public enum IPKError: Error, Sendable {
    /// The provided path does not point to a valid iPod directory.
    case invalidPath(String)

    /// No supported database was found at the given path.
    case noDatabaseFound

    /// No artwork is available for the requested track or size.
    case artworkNotFound

    /// The artwork image could not be decoded.
    case artworkDecodingFailed

    /// The database is corrupted and cannot be parsed.
    case corruptedData

    /// A database-level error occurred.
    case databaseError(String)
}

extension IPKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid iPod path: \(path)"
        case .noDatabaseFound:
            return "No supported database found on the iPod"
        case .artworkNotFound:
            return "Artwork not found"
        case .artworkDecodingFailed:
            return "Failed to decode artwork image"
        case .corruptedData:
            return "Data appears to be corrupted"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
