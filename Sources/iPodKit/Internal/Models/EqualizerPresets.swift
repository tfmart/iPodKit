//
//  EqualizerPresets.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Equalizer Presets File parser for iPod database
/// 
/// The Equalizer Presets file stores custom equalizer presets created in iTunes.
/// Note: iPods don't actually use this file yet according to documentation.
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#Equalizer_Presets_File
internal struct EqualizerPresets: IPKParseable, Sendable {
    // Binary fields
    let headerLength: UInt32
    let entryLength: UInt32
    let numberOfPresets: UInt32
    
    // Equalizer preset entries
    let presets: [EqualizerPreset]
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mqed")
        
        // Parse header fields
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.entryLength = try Self.entryLengthField.readUInt32(from: data)
        self.numberOfPresets = try Self.numberOfPresetsField.readUInt32(from: data)
        
        // Parse preset entries
        var presets: [EqualizerPreset] = []
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfPresets {
            guard offset + Int(entryLength) <= data.count else { break }
            
            let presetData = data.subdata(in: offset..<(offset + Int(entryLength)))
            let preset = try EqualizerPreset(from: presetData)
            presets.append(preset)
            
            offset += Int(entryLength)
        }
        
        self.presets = presets
    }
}

// MARK: - Internal API
extension EqualizerPresets {
    /// Check if any presets are defined
    var hasPresets: Bool {
        return !presets.isEmpty
    }
}

// MARK: - Field Definitions

extension EqualizerPresets {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let entryLengthField = IPKBinaryField(offset: 8, length: 4)
    static let numberOfPresetsField = IPKBinaryField(offset: 12, length: 4)
}
