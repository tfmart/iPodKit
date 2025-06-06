#!/usr/bin/env swift

import Foundation
import iPodKit

// Get file path from command line arguments
guard CommandLine.arguments.count > 1 else {
    print("Usage: analyze-itunes-db [options] /path/to/file")
    print("")
    print("Options:")
    print("  --debug      Debug mode for iTunesDB")
    print("  --detailed   Detailed debug for iTunesDB")
    print("  --structure  Structure analysis for iTunesDB")
    print("  --artwork    Parse ArtworkDB file")
    print("  --ipod       Parse entire iPod directory")
    print("")
    print("Examples:")
    print("  analyze-itunes-db ~/Desktop/iTunesDB")
    print("  analyze-itunes-db --artwork ~/Desktop/ArtworkDB")
    print("  analyze-itunes-db --ipod /Volumes/iPod")
    print("  analyze-itunes-db --debug ~/Desktop/iTunesDB")
    exit(1)
}

// Check for debug mode
if CommandLine.arguments[1] == "--debug" && CommandLine.arguments.count > 2 {
    debugITunesDB(filePath: CommandLine.arguments[2])
    exit(0)
}

if CommandLine.arguments[1] == "--detailed" && CommandLine.arguments.count > 2 {
    detailedDebugITunesDB(filePath: CommandLine.arguments[2])
    exit(0)
}

if CommandLine.arguments[1] == "--structure" && CommandLine.arguments.count > 2 {
    debugITunesDBStructure(filePath: CommandLine.arguments[2])
    exit(0)
}

if CommandLine.arguments[1] == "--artwork" && CommandLine.arguments.count > 2 {
    analyzeArtworkDB(filePath: CommandLine.arguments[2])
    exit(0)
}

if CommandLine.arguments[1] == "--ipod" && CommandLine.arguments.count > 2 {
    analyzeEntireiPod(iPodPath: CommandLine.arguments[2])
    exit(0)
}

let filePath = CommandLine.arguments[1]

// Check if file exists
guard FileManager.default.fileExists(atPath: filePath) else {
    print("❌ File not found: \(filePath)")
    print("")
    print("Try looking for iTunes DB files with:")
    print("  find /Volumes -name 'iTunesDB' 2>/dev/null")
    exit(1)
}

print("🔍 Analyzing iTunes DB file: \(filePath)")
print(String(repeating: "=", count: 50))

do {
    let reader = try iTunesDBReader(filePath: filePath)
    
    // Basic info
    print("📊 Database Information:")
    print("   Version: \(reader.version)")
    print("   Total Tracks: \(reader.trackCount)")
    print("   Total Playlists: \(reader.playlistCount)")
    print("")
    
    // Sample tracks
    print("🎵 Sample Tracks:")
    let sampleCount = min(5, reader.trackCount)
    for (index, track) in reader.tracks.prefix(sampleCount).enumerated() {
        print("   \(index + 1). \(track.displayName)")
        if let artist = track.artist, !artist.isEmpty {
            print("      👤 Artist: \(artist)")
        }
        if let album = track.album, !album.isEmpty {
            print("      💿 Album: \(album)")
        }
        if let genre = track.genre, !genre.isEmpty {
            print("      🎭 Genre: \(genre)")
        }
        print("      ⏱️  Duration: \(track.durationFormatted)")
        print("      ⭐ Rating: \(track.starRating)/5 stars")
        print("      📦 Size: \(track.fileSizeFormatted)")
        print("      🎧 Play Count: \(track.playCount)")
        print("      📅 Last Played: \(track.lastPlayedFormatted)")
        print("")
    }
    
    // Statistics
    let artists = reader.allArtists()
    let albums = reader.allAlbums()
    let genres = reader.allGenres()
    
    print("📈 Library Statistics:")
    print("   Unique Artists: \(artists.count)")
    print("   Unique Albums: \(albums.count)")
    print("   Unique Genres: \(genres.count)")
    print("")
    
    if !artists.isEmpty {
        print("👤 Artists (first 10): \(artists.prefix(10).joined(separator: ", "))")
    }
    
    if !genres.isEmpty {
        print("🎭 Genres: \(genres.joined(separator: ", "))")
    }
    
    // Calculate totals
    let totalSeconds = reader.tracks.reduce(0) { $0 + $1.durationInSeconds }
    let hours = Int(totalSeconds) / 3600
    let minutes = (Int(totalSeconds) % 3600) / 60
    print("⏰ Total Duration: \(hours)h \(minutes)m")
    
    let totalBytes = reader.tracks.reduce(0) { $0 + Double($1.size) }
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useGB, .useMB]
    formatter.countStyle = .file
    print("💾 Total Size: \(formatter.string(fromByteCount: Int64(totalBytes)))")
    
    print("")
    print("✅ Analysis complete!")
    
} catch let error as IPKError {
    print("❌ iTunes DB Error: \(error.localizedDescription)")
    exit(1)
} catch {
    print("❌ Unexpected error: \(error)")
    exit(1)
}