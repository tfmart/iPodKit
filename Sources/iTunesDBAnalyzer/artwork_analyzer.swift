import Foundation
import iPodKit

func analyzeArtworkDB(filePath: String) {
    print("🎨 Analyzing ArtworkDB file: \(filePath)")
    print(String(repeating: "=", count: 60))
    
    guard FileManager.default.fileExists(atPath: filePath) else {
        print("❌ File not found: \(filePath)")
        return
    }
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let artworkDB = try ArtworkDatabase(from: data)
        
        print("✅ Successfully parsed ArtworkDB!")
        print("")
        
        // Basic info
        print("📊 Database Information:")
        print("   Version: \(artworkDB.versionNumber)")
        print("   Header Length: \(artworkDB.headerLength) bytes")
        print("   Total Length: \(artworkDB.totalLength) bytes")
        print("   Number of Children: \(artworkDB.numberOfChildren)")
        print("   Albums: \(artworkDB.albums.count)")
        print("   Images: \(artworkDB.images.count)")
        print("   Total Artwork Size: \(artworkDB.formattedTotalSize)")
        print("")
        
        // Show available image dimensions
        if !artworkDB.images.isEmpty {
            let dimensions = artworkDB.uniqueImageDimensions()
            print("📐 Available Image Sizes:")
            for dim in dimensions {
                let count = artworkDB.images.filter { $0.imageWidth == dim.width && $0.imageHeight == dim.height }.count
                print("   \(dim.width)×\(dim.height) (\(count) images)")
            }
            print("")
        }
        
        // Show sample images
        print("🖼️ Sample Images:")
        let sampleCount = min(10, artworkDB.images.count)
        for (index, image) in artworkDB.images.prefix(sampleCount).enumerated() {
            print("   \(index + 1). Image ID: \(image.imageId)")
            print("      Size: \(image.formattedSize)")
            print("      Dimensions: \(image.imageWidth)×\(image.imageHeight)")
            print("      Correlation ID: \(image.correlationId)")
            print("      Aspect Ratio: \(String(format: "%.2f", image.aspectRatio))")
            if image.horizontalPadding > 0 || image.verticalPadding > 0 {
                print("      Padding: H:\(image.horizontalPadding) V:\(image.verticalPadding)")
            }
            print("")
        }
        
        // Show sample albums
        if !artworkDB.albums.isEmpty {
            print("📁 Sample Albums:")
            let albumSampleCount = min(5, artworkDB.albums.count)
            for (index, album) in artworkDB.albums.prefix(albumSampleCount).enumerated() {
                print("   \(index + 1). Artwork ID: \(album.artworkId)")
                print("      Unknown Value: \(album.unknownValue)")
                
                // Find related images
                let relatedImages = artworkDB.images(withCorrelationId: album.artworkId)
                if !relatedImages.isEmpty {
                    print("      Related Images: \(relatedImages.count)")
                    for img in relatedImages {
                        print("        - \(img.imageWidth)×\(img.imageHeight) (\(img.formattedSize))")
                    }
                }
                print("")
            }
        }
        
        // Statistics
        print("📈 Statistics:")
        if !artworkDB.images.isEmpty {
            let totalSize = artworkDB.totalArtworkSize
            let averageSize = totalSize / UInt64(artworkDB.images.count)
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            print("   Average Image Size: \(formatter.string(fromByteCount: Int64(averageSize)))")
            
            let maxSize = artworkDB.images.max { $0.imageSize < $1.imageSize }
            let minSize = artworkDB.images.min { $0.imageSize < $1.imageSize }
            
            if let max = maxSize {
                print("   Largest Image: \(max.formattedSize) (\(max.imageWidth)×\(max.imageHeight))")
            }
            if let min = minSize {
                print("   Smallest Image: \(min.formattedSize) (\(min.imageWidth)×\(min.imageHeight))")
            }
        }
        
        print("")
        print("✅ ArtworkDB analysis complete!")
        
    } catch let error as IPKError {
        print("❌ iPodKit Error: \(error.localizedDescription)")
    } catch {
        print("❌ Unexpected error: \(error)")
    }
}

func analyzeEntireiPod(iPodPath: String) {
    print("📱 Analyzing entire iPod at: \(iPodPath)")
    print(String(repeating: "=", count: 60))

    guard FileManager.default.fileExists(atPath: iPodPath) else {
        print("❌ Directory not found: \(iPodPath)")
        return
    }

    do {
        // Use the new simplified iPod API
        let ipod = try iPod(path: iPodPath)

        print("✅ Successfully initialized iPod!")
        print("")

        // Device info
        print("📱 Device Information:")
        if let deviceName = ipod.deviceName {
            print("   Name: \(deviceName)")
        }
        print("   Type: \(ipod.deviceType.rawValue)")
        print("   Path: \(ipod.path)")
        print("   Total Tracks: \(ipod.trackCount)")
        print("   Total Playlists: \(ipod.playlistCount)")
        print("   Total Duration: \(ipod.totalDurationFormatted)")
        print("   Total Size: \(ipod.totalSizeFormatted)")
        print("")

        // Sample tracks using unified Track model
        print("🎵 Sample Tracks:")
        for track in ipod.tracks.prefix(5) {
            print("   • \(track.displayName)")
            if let artist = track.artist {
                print("     Artist: \(artist)")
            }
            if let album = track.album {
                print("     Album: \(album)")
            }
            print("     Duration: \(track.durationFormatted)")
            print("     Play Count: \(track.playCount)")
            print("     Last Played: \(track.lastPlayedFormatted)")
            print("")
        }

        // Recently played
        let recentlyPlayed = ipod.recentlyPlayed(limit: 5)
        if !recentlyPlayed.isEmpty {
            print("🕐 Recently Played:")
            for track in recentlyPlayed {
                print("   • \(track.displayName) - \(track.lastPlayedFormatted)")
            }
            print("")
        }

        // Most played
        let mostPlayed = ipod.mostPlayed(limit: 5)
        if !mostPlayed.isEmpty {
            print("🔥 Most Played:")
            for track in mostPlayed {
                print("   • \(track.displayName) - \(track.playCount) plays")
            }
            print("")
        }

        // Statistics
        print("📈 Library Statistics:")
        print("   Unique Artists: \(ipod.artists.count)")
        print("   Unique Albums: \(ipod.albums.count)")
        print("   Unique Genres: \(ipod.genres.count)")
        print("   Total Play Count: \(ipod.totalPlayCount)")
        print("")

        // Access raw databases for detailed analysis (progressive disclosure)
        let databases = ipod.databases

        if let artworkDB = databases.artwork {
            print("🎨 Artwork Database:")
            print("   Albums: \(artworkDB.albums.count)")
            print("   Images: \(artworkDB.images.count)")
            print("   Total Size: \(artworkDB.formattedTotalSize)")
            print("   Available Sizes: \(artworkDB.uniqueImageDimensions().map { "\($0.width)×\($0.height)" }.joined(separator: ", "))")
            print("")
        }

        if let photoDB = databases.photos {
            print("📸 Photo Database:")
            print("   Albums: \(photoDB.albums.count)")
            print("   Images: \(photoDB.images.count)")
            print("   Total Size: \(photoDB.formattedTotalSize)")
            print("   JPEG Images: \(photoDB.jpegImages().count)")
            print("   PNG Images: \(photoDB.pngImages().count)")
            print("")
        }

        if let playCountsDB = databases.playCounts {
            print("🎧 Play Counts Database:")
            print("   Total Entries: \(playCountsDB.entries.count)")
            print("   Played Tracks: \(playCountsDB.playedEntries().count)")
            print("")
        }

        if let otgPlaylist = databases.otgPlaylist {
            print("🎵 On-The-Go Playlist:")
            print("   Tracks: \(otgPlaylist.count)")
            print("   Is Empty: \(otgPlaylist.isEmpty)")
            print("")
        }

        if let eqPresets = databases.equalizerPresets {
            print("🎛️ Equalizer Presets:")
            print("   Presets: \(eqPresets.presets.count)")
            print("   Preset Names: \(eqPresets.allPresetNames().joined(separator: ", "))")
            print("")
        }

        // iPod Shuffle specific
        if let shuffleDB = databases.shuffleDB {
            print("🔀 iPod Shuffle Database:")
            print("   Version: \(shuffleDB.versionNumber)")
            print("   Tracks: \(shuffleDB.numberOfTracks)")
            print("   Total Duration: \(shuffleDB.totalDurationFormatted)")
            print("   File Types: \(shuffleDB.uniqueFileExtensions().joined(separator: ", "))")
            print("")
        }

        if let shuffleStats = databases.shuffleStats {
            print("📊 Shuffle Statistics:")
            print("   Entries: \(shuffleStats.entries.count)")
            print("   Played Tracks: \(shuffleStats.playedTrackCount)")
            print("   Average Rating: \(String(format: "%.1f", shuffleStats.averageStarRating)) stars")
            print("   Total Play Count: \(shuffleStats.totalPlayCount)")
            print("")
        }

        if let playbackState = databases.playbackState {
            print("⏯️ Playback State:")
            let summary = playbackState.summary
            print("   Current Track: \(summary["currentTrack"] ?? "Unknown")")
            print("   Position: \(summary["position"] ?? "Unknown")")
            print("   Volume: \(summary["volume"] ?? "Unknown")")
            print("   Playing: \(summary["isPlaying"] ?? false)")
            print("   Shuffle: \(summary["shuffleMode"] ?? "Unknown")")
            print("")
        }

        print("✅ Complete iPod analysis finished!")

    } catch {
        print("❌ Failed to analyze iPod: \(error)")
    }
}