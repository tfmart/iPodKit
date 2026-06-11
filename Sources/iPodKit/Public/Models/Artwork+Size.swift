//
//  Artwork+Size.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation

extension Artwork {
    /// A thumbnail size stored in the iPod's artwork database.
    ///
    /// Use the values from ``Artwork/sizes`` to request a specific thumbnail
    /// with ``Artwork/image(size:)``.
    public struct Size: Sendable, Hashable {
        /// Thumbnail width in pixels.
        public let width: Int

        /// Thumbnail height in pixels.
        public let height: Int

        /// Creates a thumbnail size.
        ///
        /// - Parameters:
        ///   - width: Thumbnail width in pixels.
        ///   - height: Thumbnail height in pixels.
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
    }
}
