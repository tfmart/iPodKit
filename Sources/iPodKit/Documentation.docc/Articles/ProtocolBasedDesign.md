# Protocol-Based Design

How iPodKit uses Swift protocols to create a flexible, extensible architecture.

## Overview

iPodKit's architecture is built around a carefully designed protocol hierarchy that promotes code reuse, type safety, and extensibility. This design allows the framework to handle diverse binary formats while maintaining a consistent, easy-to-use API.

## Protocol Hierarchy

```
IPKObject                    // Base protocol for all database objects
    ↓
IPKParseable                 // Objects that can be parsed from binary data
    ↓
Concrete Types              // ITDBTrack, PlayCounts, ArtworkDatabase, etc.
```

### Base Layer: IPKObject

All database objects implement ``IPKObject``, which provides:

```swift
protocol IPKObject {
    var id: String { get }
}
```

This simple protocol establishes the foundation for:
- **Magic Number Validation**: Every database object has a unique identifier
- **Common Utilities**: Shared functionality through protocol extensions
- **Type Identity**: Runtime type checking and debugging

### Parsing Layer: IPKParseable

Objects that can be created from binary data implement ``IPKParseable``:

```swift
protocol IPKParseable: IPKObject {
    init(from data: Data) throws
}
```

This protocol enables:
- **Consistent Initialization**: All parsers use the same interface
- **Error Propagation**: Standardized error handling across all parsers
- **Generic Processing**: Code can work with any parseable type

### Field Definition: IPKField

Binary field layouts are defined using ``IPKField``:

```swift
protocol IPKField {
    var offset: Int { get }
    var length: Int { get }
}
```

This protocol provides:
- **Self-Documenting Code**: Field definitions serve as documentation
- **Type Safety**: Compile-time verification of field access
- **Reusable Components**: Common field types can be shared

## Protocol Extensions for Shared Behavior

### IPKObject Extensions

Common functionality is provided through protocol extensions:

```swift
extension IPKObject {
    static func validateMagicNumber(from data: Data, expectedId: String) throws {
        // Validation logic shared by all database objects
    }
    
    var header: IPKObjectHeader {
        return IPKObjectHeader()
    }
    
    var totalLength: IPKObjectTotalLength {
        return IPKObjectTotalLength()
    }
}
```

### IPKField Extensions

Type-safe reading methods are provided for all field types:

```swift
extension IPKField {
    func readUInt8(from data: Data) throws -> UInt8 { /* ... */ }
    func readUInt16(from data: Data) throws -> UInt16 { /* ... */ }
    func readUInt32(from data: Data) throws -> UInt32 { /* ... */ }
    func readString(from data: Data) throws -> String { /* ... */ }
}
```

This eliminates boilerplate code and ensures consistent error handling.

## Benefits of Protocol-Based Design

### 1. Extensibility

Adding new database formats requires only implementing the protocols:

```swift
public struct NewDatabaseFormat: IPKParseable {
    let id: String = "newf"
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: id)
        // Parse specific fields...
    }
}
```

### 2. Type Safety

The compiler enforces protocol conformance:

```swift
// This won't compile if MyStruct doesn't implement IPKParseable
func parseDatabase<T: IPKParseable>(_ type: T.Type, from data: Data) throws -> T {
    return try T(from: data)
}
```

### 3. Code Reuse

Common functionality is shared across all implementations:

- Magic number validation
- Error handling patterns
- Field reading methods
- Debug utilities

### 4. Testability

Protocols enable easy mocking and testing:

```swift
struct MockParseable: IPKParseable {
    let id = "mock"
    init(from data: Data) throws { /* Test implementation */ }
}
```

## Generic Programming with Protocols

iPodKit leverages protocols to enable generic programming:

```swift
extension iPodDBReader {
    func parseOptionalFile<T: IPKParseable>(_ type: T.Type, at path: String) -> T? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return try? T(from: data)
    }
}
```

This allows the unified reader to handle any database format without duplicated code.

## Protocol Composition

Complex behaviors are created by composing simple protocols:

```swift
// A type that can be both parsed and serialized
typealias DatabaseObject = IPKParseable & Codable

// A field that provides additional metadata
protocol ExtendedField: IPKField {
    var description: String { get }
    var dataType: DataType { get }
}
```

## Best Practices

### 1. Keep Protocols Focused

Each protocol has a single, clear responsibility:
- ``IPKObject``: Object identity
- ``IPKParseable``: Binary parsing
- ``IPKField``: Field definition

### 2. Use Extensions for Implementation

Provide default implementations through extensions:

```swift
extension IPKParseable {
    // Default validation that all parsers can use
    func validateHeaderLength(_ expected: Int, actual: Int) throws {
        guard actual >= expected else {
            throw IPKError.insufficientData
        }
    }
}
```

### 3. Compose Through Associated Types

Use associated types to create flexible relationships:

```swift
protocol DatabaseReader {
    associatedtype DatabaseType: IPKParseable
    func read() throws -> DatabaseType
}
```

## See Also

- ``IPKObject``
- ``IPKParseable``
- ``IPKField``
- <doc:BinaryParsingFramework>