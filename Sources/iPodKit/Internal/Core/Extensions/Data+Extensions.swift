//
//  Data+Extensions.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

extension Data {
    func readUInt8(at offset: Int) throws -> UInt8 {
        guard offset >= 0 && offset < count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        return self[offset]
    }
    
    func readUInt16(at offset: Int) throws -> UInt16 {
        guard offset >= 0 && offset + 1 < count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }

    func readInt16(at offset: Int) throws -> Int16 {
        let unsigned = try readUInt16(at: offset)
        return Int16(bitPattern: unsigned)
    }
    
    func readUInt32(at offset: Int) throws -> UInt32 {
        guard offset >= 0 && offset + 3 < count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        return UInt32(self[offset]) |
               (UInt32(self[offset + 1]) << 8) |
               (UInt32(self[offset + 2]) << 16) |
               (UInt32(self[offset + 3]) << 24)
    }

    func readInt32(at offset: Int) throws -> Int32 {
        let unsigned = try readUInt32(at: offset)
        return Int32(bitPattern: unsigned)
    }

    func readUInt64(at offset: Int) throws -> UInt64 {
        guard offset >= 0 && offset + 7 < count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        let low = try readUInt32(at: offset)
        let high = try readUInt32(at: offset + 4)
        return UInt64(low) | (UInt64(high) << 32)
    }
    
    func readString(at offset: Int, length: Int) throws -> String {
        guard offset >= 0 && offset + length <= count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        let data = subdata(in: offset..<(offset + length))
        guard let string = String(data: data, encoding: .ascii) else {
            throw IPKParsingError.invalidString
        }
        return string.trimmingCharacters(in: .controlCharacters)
    }
    
    func readUTF16String(at offset: Int, length: Int) throws -> String {
        guard offset >= 0 && offset + length <= count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        let data = subdata(in: offset..<(offset + length))
        guard let string = String(data: data, encoding: .utf16LittleEndian) else {
            throw IPKParsingError.invalidString
        }
        return string.trimmingCharacters(in: .controlCharacters.union(.whitespacesAndNewlines))
    }
    
    func readUTF8String(at offset: Int, length: Int) throws -> String {
        guard offset >= 0 && offset + length <= count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        let data = subdata(in: offset..<(offset + length))
        guard let string = String(data: data, encoding: .utf8) else {
            throw IPKParsingError.invalidString
        }
        return string.trimmingCharacters(in: .controlCharacters.union(.whitespacesAndNewlines))
    }
    
    func readMHODString(at offset: Int, length: Int) throws -> String {
        // Try UTF-16 first (more common in iTunes DB), then UTF-8
        var result: String
        if let utf16String = try? readUTF16String(at: offset, length: length), !utf16String.isEmpty {
            result = utf16String
        } else {
            result = try readUTF8String(at: offset, length: length)
        }
        
        // Clean up common iTunes DB string artifacts
        // Remove leading padding characters that are often present
        var cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove single character + whitespace prefix pattern (common in iTunes DB)
        if cleaned.count > 4 {
            let prefix = String(cleaned.prefix(4))
            // Check if it's a single char followed by spaces
            if prefix.count >= 2 && !prefix.first!.isLetter && !prefix.first!.isNumber {
                let afterFirstChar = String(prefix.dropFirst())
                if afterFirstChar.allSatisfy({ $0.isWhitespace }) {
                    cleaned = String(cleaned.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Remove any remaining leading non-letter/number characters
        while !cleaned.isEmpty {
            let firstChar = cleaned.first!
            if firstChar.isLetter || firstChar.isNumber || firstChar == "(" || firstChar == "[" || firstChar == "\"" {
                break
            }
            cleaned = String(cleaned.dropFirst())
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func readBytes(at offset: Int, length: Int) throws -> Data {
        guard offset >= 0 && offset + length <= count else {
            throw IPKParsingError.invalidOffset(offset)
        }
        return subdata(in: offset..<(offset + length))
    }
}