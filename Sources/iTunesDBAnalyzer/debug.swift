import Foundation
import iPodKit

func debugITunesDB(filePath: String) {
    print("🔍 Debug Analysis: \(filePath)")
    print("=" * 50)
    
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
        print("❌ Could not read file")
        return
    }
    
    print("📊 File Info:")
    print("   Size: \(data.count) bytes")
    print("   First 16 bytes: \(data.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " "))")
    
    // Check magic number
    if data.count >= 4 {
        let magicBytes = data.prefix(4)
        let magicString = String(data: magicBytes, encoding: .ascii) ?? "???"
        print("   Magic Number: '\(magicString)' (should be 'mhbd')")
        
        if magicString == "mhbd" {
            print("   ✅ Magic number is correct")
            
            // Try to read header length
            if data.count >= 8 {
                let headerLength = data.withUnsafeBytes { bytes in
                    bytes.load(fromByteOffset: 4, as: UInt32.self).littleEndian
                }
                print("   Header Length: \(headerLength)")
                
                // Try to read total length
                let totalLength = data.withUnsafeBytes { bytes in
                    bytes.load(fromByteOffset: 8, as: UInt32.self).littleEndian
                }
                print("   Total Length: \(totalLength)")
                
                // Try to read version
                if data.count >= 20 {
                    let version = data.withUnsafeBytes { bytes in
                        bytes.load(fromByteOffset: 16, as: UInt32.self).littleEndian
                    }
                    print("   Version: \(version)")
                }
            }
        } else {
            print("   ❌ Wrong magic number! Expected 'mhbd', got '\(magicString)'")
        }
    }
    
    // Try to parse with detailed error
    print("\n🧪 Attempting to parse:")
    do {
        let reader = try iTunesDBReader(filePath: filePath)
        print("   ✅ Success! \(reader.trackCount) tracks found")
    } catch let error as IPKError {
        print("   ❌ IPKError: \(error)")
        switch error {
        case .invalidMagicNumber(let expected, let found):
            print("      Expected: '\(expected)', Found: '\(found)'")
        case .invalidOffset(let offset):
            print("      Bad offset: \(offset)")
        case .corruptedData:
            print("      Data corruption detected")
        case .insufficientData:
            print("      Not enough data to parse")
        case .invalidString:
            print("      String decoding failed")
        case .fieldSizeMismatch(let expected, let actual, let field):
            print("      Field size mismatch in \(field): expected \(expected), got \(actual)")
        }
    } catch {
        print("   ❌ Other error: \(error)")
    }
}

// Helper for string repetition
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}