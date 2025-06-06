import Foundation
import iPodKit

func debugITunesDBStructure(filePath: String) {
    print("🔍 iTunes DB Structure Debug: \(filePath)")
    print("=" * 60)
    
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
        print("❌ Could not read file")
        return
    }
    
    do {
        // Parse the database manually to see the structure
        let database = try iTunesDB(from: data)
        print("📊 Database Header:")
        print("   Magic: mhbd")
        print("   Version: \(database.versionNumber)")
        print("   Header Length: \(database.headerLength)")
        print("   Total Length: \(database.totalLength)")
        print("   Number of Children: \(database.numberOfChildren)")
        print("")
        
        // Parse each dataset manually
        var offset = Int(database.headerLength)
        
        for i in 0..<database.numberOfChildren {
            print("📁 DataSet \(i + 1):")
            guard offset + 16 <= data.count else {
                print("   ❌ Not enough data for dataset")
                break
            }
            
            let dataSetData = data.subdata(in: offset..<data.count)
            let dataSet = try iTunesDBDataSet(from: dataSetData)
            
            print("   Magic: \(String(data: dataSetData.prefix(4), encoding: .ascii) ?? "???")")
            print("   Header Length: \(dataSet.headerLength)")
            print("   Total Length: \(dataSet.totalLength)")
            print("   Type: \(dataSet.type)")
            
            if dataSet.type == 1 {
                print("   📚 This is a Track List")
                
                // Parse track list header
                let trackListOffset = Int(dataSet.headerLength)
                let trackListData = dataSetData.subdata(in: trackListOffset..<dataSetData.count)
                
                if trackListData.count >= 12 {
                    let trackListMagic = String(data: trackListData.prefix(4), encoding: .ascii) ?? "???"
                    let trackListHeaderLength = trackListData.withUnsafeBytes { bytes in
                        bytes.load(fromByteOffset: 4, as: UInt32.self).littleEndian
                    }
                    let numberOfSongs = trackListData.withUnsafeBytes { bytes in
                        bytes.load(fromByteOffset: 8, as: UInt32.self).littleEndian
                    }
                    
                    print("      Track List Magic: \(trackListMagic)")
                    print("      Track List Header Length: \(trackListHeaderLength)")
                    print("      Number of Songs: \(numberOfSongs)")
                    
                    if numberOfSongs <= 100 { // Reasonable limit
                        print("      ✅ This looks correct!")
                    } else {
                        print("      ⚠️ This seems too high - possible parsing error")
                    }
                }
            } else if dataSet.type == 2 {
                print("   📋 This is a Playlist List")
            } else {
                print("   ❓ Unknown type: \(dataSet.type)")
            }
            
            offset += Int(dataSet.totalLength)
            print("")
        }
        
    } catch {
        print("❌ Parse error: \(error)")
    }
}

// String repetition helper defined in debug.swift