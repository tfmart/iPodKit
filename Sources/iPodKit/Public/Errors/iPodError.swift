//
//  iPodError.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Errors thrown by iPodKit.
public enum iPodError: Error, Sendable {
    /// The provided path does not point to a supported iPod database file or directory.
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

    /// The operation was cancelled.
    case cancelled
}

extension iPodError: LocalizedError {
    /// A human-readable description of the error, suitable for display.
    public var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "The file or directory is not a supported iPod database."
        case .noDatabaseFound:
            return "No supported iPod database was found."
        case .artworkNotFound:
            return "Artwork was not found."
        case .artworkDecodingFailed:
            return "The artwork image could not be decoded."
        case .corruptedData:
            return "The iPod database appears to be corrupted."
        case .databaseError(let message):
            return "Database error: \(message)"
        case .cancelled:
            return "The operation was cancelled."
        }
    }

    /// A suggestion for recovering from the error.
    public var recoverySuggestion: String? {
        switch self {
        case .invalidPath:
            return "Choose an iTunesDB, iTunesSD, Library.itdb, or a directory that contains one of those files."
        case .noDatabaseFound:
            return "Check that the selected location contains a supported iPod database file."
        case .artworkNotFound:
            return "Check the track's available artwork sizes before requesting an image."
        case .artworkDecodingFailed:
            return "Try another available artwork size, or reload the database and try again."
        case .corruptedData:
            return "Try reading a fresh copy of the database file."
        case .databaseError:
            return "Try reading the database again."
        case .cancelled:
            return "Start the operation again when you are ready."
        }
    }
}
