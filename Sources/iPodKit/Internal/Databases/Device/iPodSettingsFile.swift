//
//  iPodSettingsFile.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// Parser for the device settings file (`iPod_Control/Device/iPodSettings.xml`).
///
/// The file is plain XML with one section per settings area, for example:
///
/// ```xml
/// <iPodSettings version="1.0">
///   <Settings><SoftwareVersion>1.0.4 (37A40005)</SoftwareVersion></Settings>
///   <General><Language>en-US</Language><Brightness>40</Brightness></General>
///   <Playback><VolumeLimit>232</VolumeLimit><Shuffle>songs</Shuffle></Playback>
/// </iPodSettings>
/// ```
internal struct iPodSettingsFile: Sendable {
    /// Element values keyed by "Section/Element" (e.g., "General/Language").
    let values: [String: String]

    init(from data: Data) {
        let delegate = SettingsXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        self.values = delegate.values
    }

    /// Value for a "Section/Element" key.
    func string(_ key: String) -> String? {
        guard let value = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }

    func int(_ key: String) -> Int? {
        string(key).flatMap(Int.init)
    }

    func bool(_ key: String) -> Bool? {
        guard let value = string(key) else { return nil }
        switch value.lowercased() {
        case "1", "on", "true": return true
        case "0", "off", "false": return false
        default: return nil
        }
    }
}

// MARK: - XML Delegate

private final class SettingsXMLDelegate: NSObject, XMLParserDelegate {
    var values: [String: String] = [:]

    private var path: [String] = []
    private var currentText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        path.append(elementName)
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
        // Record leaf values as "Section/Element" (skipping the root element).
        if !currentText.isEmpty, path.count >= 3 {
            let key = path.dropFirst().joined(separator: "/")
            values[key] = currentText
        }
        currentText = ""
        if path.last == elementName {
            path.removeLast()
        }
    }
}
