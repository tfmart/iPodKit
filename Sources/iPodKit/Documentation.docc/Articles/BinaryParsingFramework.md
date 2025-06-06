# Binary Parsing Framework

Understanding iPodKit's type-safe approach to parsing binary iTunes database files.

## Overview

iPodKit's binary parsing framework provides a robust, type-safe approach to reading the complex binary formats used by iTunes databases. The framework is built around three core protocols that work together to ensure data integrity and developer productivity.

## Core Protocols

### IPKField: Defining Binary Layouts

The ``IPKField`` protocol defines the location and size of data fields within binary structures:

```swift
protocol IPKField {
    var offset: Int { get }  // Byte offset from start of data
    var length: Int { get }  // Size in bytes
}
```

Each database structure defines its binary layout using nested `IPKField` implementations:

```swift
extension ITDBTrack {
    struct UniqueId: IPKField {
        var offset: Int { 16 }  // Starts at byte 16
        var length: Int { 4 }   // 4 bytes (UInt32)
    }
    
    struct Title: IPKField {
        var offset: Int { 32 }
        var length: Int { 256 } // Variable length string
    }
}
```

### IPKParseable: Creating Objects from Data

The ``IPKParseable`` protocol defines objects that can be initialized from binary data:

```swift
protocol IPKParseable: IPKObject {
    init(from data: Data) throws
}
```

Implementations handle the complete parsing logic:

```swift
public struct ITDBTrack: IPKParseable {
    public init(from data: Data) throws {
        // Validate magic number
        try Self.validateMagicNumber(from: data, expectedId: "mhit")
        
        // Parse binary fields
        self.uniqueId = try Self.UniqueId().readUInt32(from: data)
        self.title = try Self.Title().readString(from: data)
        
        // Parse complex nested structures
        // ...
    }
}
```

### IPKObject: Common Database Object Behavior

The ``IPKObject`` protocol provides shared functionality for all database objects:

```swift
protocol IPKObject {
    var id: String { get }  // Magic number identifier
}
```

Extension methods provide validation and common field access:

```swift
extension IPKObject {
    static func validateMagicNumber(from data: Data, expectedId: String) throws {
        let magicNumber = try data.readString(at: 0, length: 4)
        guard magicNumber == expectedId else {
            throw IPKError.invalidMagicNumber(expected: expectedId, found: magicNumber)
        }
    }
}
```

## Type-Safe Reading Methods

The ``IPKField`` protocol extension provides type-safe methods for reading binary data:

```swift
extension IPKField {
    func readUInt32(from data: Data) throws -> UInt32 {
        guard length == 4 else {
            throw IPKError.fieldSizeMismatch(expected: 4, actual: length, field: "\(type(of: self))")
        }
        return try data.readUInt32(at: offset)
    }
    
    func readString(from data: Data) throws -> String {
        return try data.readString(at: offset, length: length)
    }
}
```

This approach provides several benefits:

- **Compile-time Safety**: Field sizes are validated at runtime
- **Self-Documenting**: Field definitions serve as documentation
- **Maintainable**: Changes to binary formats only require updating field definitions
- **Debuggable**: Clear error messages when parsing fails

## Endianness Handling

iPodKit automatically handles different byte orders used by different iPod models:

```swift
// Little-endian (standard iPods)
let value = try data.readUInt32(at: offset)

// Big-endian (iPod Shuffle)
let value = try data.readUInt32BigEndian(at: offset)
```

## String Parsing

iTunes databases use complex string encodings with format-specific artifacts. The parsing framework handles:

- **Encoding Detection**: Automatic UTF-16/UTF-8 detection
- **Artifact Removal**: Cleanup of iTunes-specific padding and control characters
- **Null Termination**: Proper handling of null-terminated strings

```swift
func readMHODString(at offset: Int, length: Int) throws -> String {
    // Try UTF-16 first, fallback to UTF-8
    var result: String
    if let utf16String = try? readUTF16String(at: offset, length: length) {
        result = utf16String
    } else {
        result = try readUTF8String(at: offset, length: length)
    }
    
    // Clean up iTunes-specific artifacts
    return cleanupString(result)
}
```

## Error Handling

The framework provides detailed error information through the ``IPKError`` enum:

```swift
public enum IPKError: Error {
    case invalidOffset(Int)
    case invalidMagicNumber(expected: String, found: String)
    case fieldSizeMismatch(expected: Int, actual: Int, field: String)
    case insufficientData
}
```

Each error includes context about what went wrong and where, making debugging straightforward.

## See Also

- ``IPKField``
- ``IPKParseable`` 
- ``IPKObject``
- ``IPKError``