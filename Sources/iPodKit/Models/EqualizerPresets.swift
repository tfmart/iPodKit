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
struct EqualizerPresets: IPKParseable, Sendable {
    // Binary fields
    public let headerLength: UInt32
    public let entryLength: UInt32
    public let numberOfPresets: UInt32
    
    // Equalizer preset entries
    public let presets: [EqualizerPreset]
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mqed")
        
        // Parse header fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.entryLength = try Self.EntryLength().readUInt32(from: data)
        self.numberOfPresets = try Self.NumberOfPresets().readUInt32(from: data)
        
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

// MARK: - Equalizer Preset Entry
struct EqualizerPreset: IPKParseable, Sendable {
    // Binary fields - 10 frequency bands typical for iTunes EQ
    public let band32Hz: Int16
    public let band64Hz: Int16
    public let band125Hz: Int16
    public let band250Hz: Int16
    public let band500Hz: Int16
    public let band1kHz: Int16
    public let band2kHz: Int16
    public let band4kHz: Int16
    public let band8kHz: Int16
    public let band16kHz: Int16
    public let preamp: Int16
    
    // Preset name
    public let name: String?
    
    public init(from data: Data) throws {
        // Note: EQ preset entries may not have magic numbers in some versions
        guard data.count >= 22 else {
            throw IPKError.insufficientData
        }
        
        // Read 10 frequency bands (2 bytes each) + preamp
        self.band32Hz = try Int16(bitPattern: data.readUInt16(at: 0))
        self.band64Hz = try Int16(bitPattern: data.readUInt16(at: 2))
        self.band125Hz = try Int16(bitPattern: data.readUInt16(at: 4))
        self.band250Hz = try Int16(bitPattern: data.readUInt16(at: 6))
        self.band500Hz = try Int16(bitPattern: data.readUInt16(at: 8))
        self.band1kHz = try Int16(bitPattern: data.readUInt16(at: 10))
        self.band2kHz = try Int16(bitPattern: data.readUInt16(at: 12))
        self.band4kHz = try Int16(bitPattern: data.readUInt16(at: 14))
        self.band8kHz = try Int16(bitPattern: data.readUInt16(at: 16))
        self.band16kHz = try Int16(bitPattern: data.readUInt16(at: 18))
        self.preamp = try Int16(bitPattern: data.readUInt16(at: 20))
        
        // Try to read name if there's more data
        if data.count > 22 {
            let nameData = data.subdata(in: 22..<data.count)
            self.name = try? nameData.readMHODString(at: 0, length: nameData.count)
        } else {
            self.name = nil
        }
    }
}

// MARK: - Public API
extension EqualizerPresets {
    /// Get all preset names
    /// - Returns: Array of preset names
    func allPresetNames() -> [String] {
        return presets.compactMap { $0.name }
    }
    
    /// Check if any presets are defined
    var hasPresets: Bool {
        return !presets.isEmpty
    }
}

// MARK: - Field Definitions
extension EqualizerPresets {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct EntryLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct NumberOfPresets: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}