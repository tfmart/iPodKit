//
//  iPodSettings.swift
//  iPodKit
//
//  Created by Tomas Martins on 18/02/26.
//

import Foundation

/// Parser for the iPod Settings XML file (`/iPod_Control/Device/iPodSettings.xml`).
///
/// Extracts the device timezone from the `<TimeZone>` element in the `<DateTime>` section.
/// This serves as a fallback when the binary Preferences file does not contain a timezone byte.
///
/// ## Timezone Encoding
///
/// The value is stored as half-hour increments with 68 representing UTC+0:
/// - `offset_seconds = (value - 68) * 1800`
/// - Example: 62 → (62 − 68) × 1800 = −10800s = UTC−3
struct iPodSettings: Sendable {
    let deviceTimeZone: TimeZone?

    /// UTC+0 baseline in the half-hour encoding scheme.
    private static let utcBaseline = 68

    /// Each unit represents 1800 seconds (30 minutes).
    private static let secondsPerUnit = 1800

    init(from data: Data) {
        let delegate = SettingsParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()

        guard let value = delegate.timeZoneValue else {
            self.deviceTimeZone = nil
            return
        }

        let offsetSeconds = (value - Self.utcBaseline) * Self.secondsPerUnit

        // Validate: UTC-12 (−43200) to UTC+14 (+50400)
        guard offsetSeconds >= -43200, offsetSeconds <= 50400 else {
            self.deviceTimeZone = nil
            return
        }

        self.deviceTimeZone = TimeZone(secondsFromGMT: offsetSeconds)
    }
}

// MARK: - XML Delegate

private final class SettingsParserDelegate: NSObject, XMLParserDelegate {
    var timeZoneValue: Int?

    private var insideDateTime = false
    private var currentText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        if elementName == "DateTime" {
            insideDateTime = true
        }
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        if elementName == "DateTime" {
            insideDateTime = false
        }

        if elementName == "TimeZone", insideDateTime {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            timeZoneValue = Int(trimmed)
        }
    }
}
