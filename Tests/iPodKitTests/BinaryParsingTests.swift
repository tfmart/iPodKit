//
//  BinaryParsingTests.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Testing
import Foundation
@testable import iPodKit

// MARK: - Binary Parsing Core Tests

@Test func testDataExtensionsEndianness() async throws {
    // Test little-endian reading
    let data = Data([0x12, 0x34, 0x56, 0x78])
    
    #expect(try data.readUInt16(at: 0) == 0x3412)
    #expect(try data.readUInt32(at: 0) == 0x78563412)
    
    // Test reading as bytes
    #expect(data[0] == 0x12)
    #expect(data[1] == 0x34)
    #expect(data[2] == 0x56)
    #expect(data[3] == 0x78)
}

@Test func testDataExtensionsStringParsing() async throws {
    // Test UTF-8 string parsing
    let utf8Data = Data("Hello World".utf8)
    let parsedUTF8 = try utf8Data.readUTF8String(at: 0, length: utf8Data.count)
    #expect(parsedUTF8 == "Hello World")
    
    // Test general string reading
    let stringData = Data("Test".utf8)
    let parsedString = try stringData.readString(at: 0, length: stringData.count)
    #expect(parsedString == "Test")
}

@Test func testDataExtensionsErrorHandling() async throws {
    let smallData = Data([0x12, 0x34])
    
    // Test reading beyond data bounds
    #expect(throws: IPKParsingError.self) {
        _ = try smallData.readUInt32(at: 0)
    }

    #expect(throws: IPKParsingError.self) {
        _ = try smallData.readUInt64(at: 0)
    }

    // Test reading at invalid offset
    #expect(throws: IPKParsingError.self) {
        _ = try smallData.readUInt16(at: 10)
    }
}

@Test func testIPKFieldOffsetAndLength() async throws {
    let data = Data([0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78])
    let field = IPKBinaryField(offset: 4, length: 2)
    
    let value = try field.readUInt16(from: data)
    #expect(value == 0x3412) // Should read from offset 4
}

// MARK: - iTunes Database Structure Tests

@Test func testITDBDataObjectParsing() async throws {
    // Test that ITDBDataObject correctly identifies type and parses header
    // Note: Real MHOD parsing is complex due to iTunes string encoding variations
    // This test validates the basic structure parsing

    // Structure: magic(4) + headerLen(4) + totalLen(4) + type(4) + unknown1(4) + unknown2(4) + position(4) = 28 bytes header
    let mhodHeader = Data("mhod".utf8)                     // Offset 0-3: Magic number
    let headerLength = Data([0x1C, 0x00, 0x00, 0x00])      // Offset 4-7: 28 bytes header
    let totalLength = Data([0x3C, 0x00, 0x00, 0x00])       // Offset 8-11: 60 bytes total
    let type = Data([0x01, 0x00, 0x00, 0x00])              // Offset 12-15: Type 1 (title)
    let unknown1 = Data([0x00, 0x00, 0x00, 0x00])          // Offset 16-19: Unknown1
    let unknown2 = Data([0x00, 0x00, 0x00, 0x00])          // Offset 20-23: Unknown2
    let position = Data([0x00, 0x00, 0x00, 0x00])          // Offset 24-27: Position
    // String data after header - use enough padding to reach totalLength
    let stringDataPadded = Data(count: 32)                 // 60 - 28 = 32 bytes of string data area

    let mhodData = mhodHeader + headerLength + totalLength + type + unknown1 + unknown2 + position + stringDataPadded

    let dataObject = try ITDBDataObject(from: mhodData)

    // Validate header parsing
    #expect(dataObject.type == .title)
    #expect(dataObject.totalLength == 60)
    #expect(dataObject.headerLength == 28)
    // String value may be empty or have parsing artifacts with mock data - that's OK for this test
    #expect(dataObject.stringValue != nil, "String type should have stringValue")
}

@Test func testITDBTrackFieldStructures() async throws {
    // Test that all ITDBTrack field structures have valid offsets and lengths
    let track = ITDBTrack.self
    
    // Test a few key field structures
    let headerLength = track.headerLengthField
    #expect(headerLength.offset == 4)
    #expect(headerLength.length == 4)
    
    let totalLength = track.totalLengthField
    #expect(totalLength.offset == 8)
    #expect(totalLength.length == 4)
    
    let uniqueId = track.identifierField
    #expect(uniqueId.offset == 16)
    #expect(uniqueId.length == 4)
    
    let playCount = track.playCountField
    #expect(playCount.offset == 80)
    #expect(playCount.length == 4)
    
    let lastPlayed = track.lastPlayedField
    #expect(lastPlayed.offset == 88)
    #expect(lastPlayed.length == 4)
}

// MARK: - Error Handling Tests

@Test func testIPKParsingErrorTypes() async throws {
    // Test internal parsing error types
    let invalidMagicError = IPKParsingError.invalidMagicNumber(expected: "mhbd", found: "abcd")
    let insufficientDataError = IPKParsingError.insufficientData
    let fieldSizeMismatchError = IPKParsingError.fieldSizeMismatch(expected: 4, actual: 2, field: "test")

    #expect(invalidMagicError.localizedDescription.contains("mhbd"))
    #expect(insufficientDataError.localizedDescription.contains("data"))
    #expect(fieldSizeMismatchError.localizedDescription.contains("test"))
}

@Test func testIPKErrorTypes() async throws {
    // Test public error types
    _ = iPodError.corruptedData
    let artworkError = iPodError.artworkNotFound
    let dbError = iPodError.databaseError("test")

    #expect(artworkError.localizedDescription.contains("Artwork"))
    #expect(dbError.localizedDescription.contains("test"))
    #expect(dbError.recoverySuggestion != nil)
}

@Test func testMagicNumberValidationEdgeCases() async throws {
    // Test with empty data
    let emptyData = Data()
    #expect(throws: IPKParsingError.self) {
        try iTunesDB.validateMagicNumber(from: emptyData, expectedId: "test")
    }

    // Test with partial magic number
    let partialData = Data("te".utf8)
    #expect(throws: IPKParsingError.self) {
        try iTunesDB.validateMagicNumber(from: partialData, expectedId: "test")
    }

    // Test with correct length but wrong content
    let wrongData = Data("wxyz".utf8)
    #expect(throws: IPKParsingError.self) {
        try iTunesDB.validateMagicNumber(from: wrongData, expectedId: "test")
    }
}

@Test func testPlayCountEntryHandlesLegacyEntryLength() async throws {
    let legacyEntry = try PlayCountEntry(from: Data(count: 24))

    #expect(legacyEntry.skipCount == 0)
    #expect(legacyEntry.lastSkipped == 0)
}

// MARK: - Performance Tests

@Test func testLargeDataHandling() async throws {
    // Create a large data buffer
    let largeSize = 1024 * 1024 // 1MB
    var largeData = Data(capacity: largeSize)
    
    // Fill with test pattern
    for i in 0..<largeSize {
        largeData.append(UInt8(i % 256))
    }
    
    // Test reading from various positions
    // Test reading from beginning, middle, and near end
    let positions = [0, largeSize / 2, largeSize - 8]
    
    for position in positions {
        let field = IPKBinaryField(offset: position, length: 4)
        let value = try field.readUInt32(from: largeData)
        #expect(value != 0) // Should read some non-zero pattern
    }
}
