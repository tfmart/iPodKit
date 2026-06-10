//
//  Artwork+Size.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation

extension Artwork {
    public struct Size: Sendable, Hashable {
        /// Thumbnail width in pixels.
        public let width: Int

        /// Thumbnail height in pixels.
        public let height: Int

        /// Creates a thumbnail size.
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
    }
}
