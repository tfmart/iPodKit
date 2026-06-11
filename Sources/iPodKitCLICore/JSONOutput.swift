//
//  JSONOutput.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation

/// Shared JSON encoding so every command emits an identical format.
package enum JSONOutput {

    package static func string<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }
}
