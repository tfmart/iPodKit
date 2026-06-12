//
//  CLISupport.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation
import iPodKit

/// A runtime failure reported without usage text (unlike ValidationError).
struct CLIError: Error, LocalizedError, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var description: String { message }
    var errorDescription: String? { message }
}

func printToStderr(_ message: String) {
    fputs(message + "\n", stderr)
}

func findTrack(withID id: UInt64, in ipod: iPod) throws -> Track {
    guard let track = ipod.tracks.first(where: { $0.id == id }) else {
        throw CLIError("No track with ID \(id). Use the tracks command to list IDs.")
    }
    return track
}
