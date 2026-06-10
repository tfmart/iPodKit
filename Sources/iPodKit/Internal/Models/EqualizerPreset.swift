//
//  EqualizerPreset.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

internal struct EqualizerPreset: IPKParseable, Sendable {
    // Binary fields - 10 frequency bands typical for iTunes EQ
    let band32Hz: Int16
    let band64Hz: Int16
    let band125Hz: Int16
    let band250Hz: Int16
    let band500Hz: Int16
    let band1kHz: Int16
    let band2kHz: Int16
    let band4kHz: Int16
    let band8kHz: Int16
    let band16kHz: Int16
    let preamp: Int16
    
    // Preset name
    let name: String?
    
    init(from data: Data) throws {
        // Note: EQ preset entries may not have magic numbers in some versions
        guard data.count >= 22 else {
            throw IPKParsingError.insufficientData
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
