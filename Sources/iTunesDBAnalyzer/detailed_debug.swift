import Foundation
import iPodKit

func detailedDebugITunesDB(filePath: String) {
    print("🔍 Detailed Debug Analysis: \(filePath)")
    print("=" * 60)
    
    guard FileManager.default.fileExists(atPath: filePath) else {
        print("❌ Could not read file")
        return
    }
    
    do {
        let reader = try iTunesDBReader(filePath: filePath)
        print("📊 Basic Info:")
        print("   Version: \(reader.version)")
        print("   Track Count: \(reader.trackCount)")
        print("   Playlist Count: \(reader.playlistCount)")
        print("")
        
        // Show first few tracks in detail
        print("🎵 First 3 Tracks (Raw Data):")
        for (index, track) in reader.tracks.prefix(3).enumerated() {
            print("   Track \(index + 1):")
            print("      Unique ID: \(track.uniqueId)")
            print("      Title: '\(track.title ?? "nil")'")
            print("      Artist: '\(track.artist ?? "nil")'")
            print("      Album: '\(track.album ?? "nil")'")
            print("      Genre: '\(track.genre ?? "nil")'")
            print("      Location: '\(track.location ?? "nil")'")
            print("      Length (ms): \(track.length)")
            print("      Size (bytes): \(track.size)")
            print("      Track Number: \(track.trackNumber)")
            print("      Year: \(track.year)")
            print("      Bitrate: \(track.bitrate)")
            print("      Rating: \(track.rating)")
            print("      Visible: \(track.visible)")
            print("      Number of Strings: \(track.numberOfStrings)")
            print("      Play Count: \(track.playCount)")
            print("      Last Played: \(track.lastPlayed) (\(track.lastPlayedFormatted))")
            print("")
        }
        
        // Check if we can find the expected tracks
        print("🔍 Looking for expected tracks:")
        let expectedTracks = ["Fields of Gold", "Sinnerman", "Bye-Ya", "I Put a Spell on You"]
        for expectedTitle in expectedTracks {
            let found = reader.tracks(withTitle: expectedTitle)
            if found.isEmpty {
                print("   ❌ '\(expectedTitle)' not found")
            } else {
                print("   ✅ '\(expectedTitle)' found: \(found.count) matches")
            }
        }
        
        // Check for expected artists
        print("\n🎤 Looking for expected artists:")
        let expectedArtists = ["Sting", "Nina Simone", "Thelonious Monk"]
        for expectedArtist in expectedArtists {
            let found = reader.tracks(byArtist: expectedArtist)
            if found.isEmpty {
                print("   ❌ '\(expectedArtist)' not found")
            } else {
                print("   ✅ '\(expectedArtist)' found: \(found.count) tracks")
            }
        }
        
    } catch {
        print("❌ Parse error: \(error)")
    }
}

// Note: String * extension is defined in debug.swift