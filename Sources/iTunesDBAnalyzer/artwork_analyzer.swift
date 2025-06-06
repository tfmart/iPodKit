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
        let reader = try iPodDBReader(iPodPath: iPodPath)
        
        print("✅ Successfully initialized iPod reader!")
        print("")
        
        // Device info
        print("📱 Device Information:")
        let deviceInfo = reader.deviceInfo
        print("   Type: \(deviceInfo["deviceType"] ?? "Unknown")")
        print("   Base Path: \(deviceInfo["basePath"] ?? "Unknown")")
        print("   Has Main Database: \(deviceInfo["hasMainDatabase"] ?? false)")
        print("   Total Tracks: \(deviceInfo["trackCount"] ?? 0)")
        print("   Total Playlists: \(deviceInfo["playlistCount"] ?? 0)")
        print("")
        
        // Loaded files
        print("📁 Loaded Database Files:")
        let loadedFiles = reader.loadedFiles
        if loadedFiles.isEmpty {
            print("   No database files found")
        } else {
            for file in loadedFiles {
                print("   ✅ \(file)")
            }
        }
        print("")
        
        // Detailed analysis of each database
        if let artworkDB = reader.artworkDB {
            print("🎨 Artwork Database:")
            print("   Albums: \(artworkDB.albums.count)")
            print("   Images: \(artworkDB.images.count)")
            print("   Total Size: \(artworkDB.formattedTotalSize)")
            print("   Available Sizes: \(artworkDB.uniqueImageDimensions().map { "\($0.width)×\($0.height)" }.joined(separator: ", "))")
            print("")
        }
        
        if let photoDB = reader.photoDB {
            print("📸 Photo Database:")
            print("   Albums: \(photoDB.albums.count)")
            print("   Images: \(photoDB.images.count)")
            print("   Total Size: \(photoDB.formattedTotalSize)")
            print("   JPEG Images: \(photoDB.jpegImages().count)")
            print("   PNG Images: \(photoDB.pngImages().count)")
            print("")
        }
        
        if let playCountsDB = reader.playCountsDB {
            print("🎧 Play Counts:")
            print("   Total Entries: \(playCountsDB.entries.count)")
            print("   Played Tracks: \(playCountsDB.playedEntries().count)")
            print("   Most Played: \(playCountsDB.mostPlayedEntries(limit: 3).map { "Track \($0.index) (\($0.entry.playCount) plays)" }.joined(separator: ", "))")
            print("")
        }
        
        if let otgPlaylist = reader.otgPlaylist {
            print("🎵 On-The-Go Playlist:")
            print("   Tracks: \(otgPlaylist.count)")
            print("   Is Empty: \(otgPlaylist.isEmpty)")
            if !otgPlaylist.isEmpty {
                print("   Track Indexes: \(otgPlaylist.trackIndexes.prefix(10).map(String.init).joined(separator: ", "))\(otgPlaylist.count > 10 ? "..." : "")")
            }
            print("")
        }
        
        if let eqPresets = reader.equalizerPresets {
            print("🎛️ Equalizer Presets:")
            print("   Presets: \(eqPresets.presets.count)")
            print("   Preset Names: \(eqPresets.allPresetNames().joined(separator: ", "))")
            print("")
        }
        
        // iPod Shuffle specific
        if let shuffleDB = reader.shuffleDB {
            print("🔀 iPod Shuffle Database:")
            print("   Version: \(shuffleDB.versionNumber)")
            print("   Tracks: \(shuffleDB.numberOfTracks)")
            print("   Total Duration: \(shuffleDB.totalDurationFormatted)")
            print("   File Types: \(shuffleDB.uniqueFileExtensions().joined(separator: ", "))")
            print("")
        }
        
        if let shuffleStats = reader.shuffleStats {
            print("📊 Shuffle Statistics:")
            print("   Entries: \(shuffleStats.entries.count)")
            print("   Played Tracks: \(shuffleStats.playedTrackCount)")
            print("   Average Rating: \(String(format: "%.1f", shuffleStats.averageStarRating)) stars")
            print("   Total Play Count: \(shuffleStats.totalPlayCount)")
            print("")
        }
        
        if let playbackState = reader.playbackState {
            print("⏯️ Playback State:")
            let summary = playbackState.summary
            print("   Current Track: \(summary["currentTrack"] ?? "Unknown")")
            print("   Position: \(summary["position"] ?? "Unknown")")
            print("   Volume: \(summary["volume"] ?? "Unknown")")
            print("   Playing: \(summary["isPlaying"] ?? false)")
            print("   Shuffle: \(summary["shuffleMode"] ?? "Unknown")")
            print("")
        }
        
        // Complete summary
        print("📋 Complete Summary:")
        let summary = reader.summary
        if let databases = summary["databases"] as? [String: Any] {
            for (dbName, dbInfo) in databases {
                print("   \(dbName): \(dbInfo)")
            }
        }
        
        print("")
        print("✅ Complete iPod analysis finished!")
        
    } catch {
        print("❌ Failed to analyze iPod: \(error)")
    }
}