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
    #expect(throws: IPKError.self) {
        _ = try smallData.readUInt32(at: 0)
    }
    
    #expect(throws: IPKError.self) {
        _ = try smallData.readUInt64(at: 0)
    }
    
    // Test reading at invalid offset
    #expect(throws: IPKError.self) {
        _ = try smallData.readUInt16(at: 10)
    }
}

@Test func testIPKFieldOffsetAndLength() async throws {
    struct TestFieldWithOffset: IPKField {
        var offset: Int { 4 }
        var length: Int { 2 }
    }
    
    let data = Data([0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78])
    let field = TestFieldWithOffset()
    
    let value = try field.readUInt16(from: data)
    #expect(value == 0x3412) // Should read from offset 4
}

// MARK: - iTunes Database Structure Tests

@Test func testITDBDataObjectParsing() async throws {
    // Create mock MHOD (iTunes Data Object) data
    let mhodHeader = "mhod".data(using: .ascii)!
    let headerLength = Data([0x18, 0x00, 0x00, 0x00]) // 24 bytes header
    let totalLength = Data([0x30, 0x00, 0x00, 0x00])  // 48 bytes total
    let type = Data([0x01, 0x00, 0x00, 0x00])         // Type 1 (title)
    let encoding = Data([0x01, 0x00, 0x00, 0x00])     // UTF-8
    let stringLength = Data([0x0C, 0x00, 0x00, 0x00]) // 12 bytes
    let stringData = "Test Title\0\0".data(using: .utf8)!
    
    let mhodData = mhodHeader + headerLength + totalLength + type + encoding + stringLength + stringData
    
    let dataObject = try ITDBDataObject(from: mhodData)
    
    #expect(dataObject.type == .title)
    #expect(dataObject.stringValue == "Test Title")
    #expect(dataObject.totalLength == 48)
}

@Test func testITDBTrackFieldStructures() async throws {
    // Test that all ITDBTrack field structures have valid offsets and lengths
    let track = ITDBTrack.self
    
    // Test a few key field structures
    let headerLength = track.HeaderLength()
    #expect(headerLength.offset == 4)
    #expect(headerLength.length == 4)
    
    let totalLength = track.TotalLength()
    #expect(totalLength.offset == 8)
    #expect(totalLength.length == 4)
    
    let uniqueId = track.Identifier()
    #expect(uniqueId.offset == 16)
    #expect(uniqueId.length == 4)
    
    let playCount = track.PlayCount()
    #expect(playCount.offset == 80)
    #expect(playCount.length == 4)
    
    let lastPlayed = track.LastPlayed()
    #expect(lastPlayed.offset == 88)
    #expect(lastPlayed.length == 4)
}

// MARK: - Error Handling Tests

@Test func testIPKErrorTypes() async throws {
    // Test different error types
    let invalidMagicError = IPKError.invalidMagicNumber(expected: "mhbd", found: "abcd")
    let insufficientDataError = IPKError.insufficientData
    let corruptedDataError = IPKError.corruptedData
    let fieldSizeMismatchError = IPKError.fieldSizeMismatch(expected: 4, actual: 2, field: "test")
    
    #expect(invalidMagicError.localizedDescription.contains("mhbd"))
    #expect(insufficientDataError.localizedDescription.contains("data"))
    #expect(fieldSizeMismatchError.localizedDescription.contains("test"))
}

@Test func testMagicNumberValidationEdgeCases() async throws {
    struct TestObject: IPKObject {
        let id: String = "test"
    }
    
    // Test with empty data
    let emptyData = Data()
    #expect(throws: IPKError.self) {
        try TestObject.validateMagicNumber(from: emptyData, expectedId: "test")
    }
    
    // Test with partial magic number
    let partialData = Data("te".utf8)
    #expect(throws: IPKError.self) {
        try TestObject.validateMagicNumber(from: partialData, expectedId: "test")
    }
    
    // Test with correct length but wrong content
    let wrongData = Data("wxyz".utf8)
    #expect(throws: IPKError.self) {
        try TestObject.validateMagicNumber(from: wrongData, expectedId: "test")
    }
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
    struct TestField: IPKField {
        let testOffset: Int
        var offset: Int { testOffset }
        var length: Int { 4 }
        
        init(offset: Int) {
            self.testOffset = offset
        }
    }
    
    // Test reading from beginning, middle, and near end
    let positions = [0, largeSize / 2, largeSize - 8]
    
    for position in positions {
        let field = TestField(offset: position)
        let value = try field.readUInt32(from: largeData)
        #expect(value != 0) // Should read some non-zero pattern
    }
}