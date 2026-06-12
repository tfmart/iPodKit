//
//  PNGWriter.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation
import CoreGraphics
import ImageIO

/// Writes decoded artwork to disk as PNG.
package enum PNGWriter {

    package enum PNGWriterError: Error, CustomStringConvertible {
        case cannotCreateFile(String)
        case writeFailed(String)

        package var description: String {
            switch self {
            case .cannotCreateFile(let path):
                return "Cannot create file at '\(path)'."
            case .writeFailed(let path):
                return "Failed to write PNG data to '\(path)'."
            }
        }
    }

    package static func write(_ image: CGImage, to url: URL) throws {
        // UTI string instead of UTType to keep the macOS 10.15 deployment target.
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, "public.png" as CFString, 1, nil
        ) else {
            throw PNGWriterError.cannotCreateFile(url.path)
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw PNGWriterError.writeFailed(url.path)
        }
    }
}
