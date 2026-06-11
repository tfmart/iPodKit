//
//  SizeParser.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import iPodKit

/// Parses "WxH" strings (e.g. "140x140") into artwork sizes.
package enum SizeParser {

    package static func parse(_ string: String) -> Artwork.Size? {
        let parts = string.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Int(parts[0]),
              let height = Int(parts[1]),
              width > 0, height > 0 else {
            return nil
        }
        return Artwork.Size(width: width, height: height)
    }
}
