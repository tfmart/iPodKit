import Foundation
import iPodKit
import CoreGraphics
import ImageIO
import CoreServices

func analyzeEntireiPod(iPodPath: String) {
    print("Analyzing iPod at: \(iPodPath)")
    print(String(repeating: "=", count: 60))

    guard FileManager.default.fileExists(atPath: iPodPath) else {
        print("Directory not found: \(iPodPath)")
        return
    }

    do {
        let ipod = try iPod(url: URL(fileURLWithPath: iPodPath))

        print("Path: \(ipod.path)")
        print("Tracks: \(ipod.tracks.count)")
        print("Playlists: \(ipod.playlists.count)")
        print("")

        print("Playlists:")
        for playlist in ipod.playlists {
            print("   \(playlist.displayName) (\(playlist.trackCount) tracks)")
        }
        print("")

        let tracksWithArtwork = ipod.tracks.filter { $0.artwork != nil }
        print("Artwork:")
        print("   Tracks with Artwork: \(tracksWithArtwork.count)")
        print("")

        print("Sample Tracks:")
        for track in ipod.tracks.prefix(10) {
            print("   \(track.displayName)")
            if let artist = track.artist {
                print("      Artist: \(artist)")
            }
            if let album = track.album {
                print("      Album: \(album)")
            }
            print("      Duration: \(track.durationFormatted)")
            if let artwork = track.artwork {
                let sizesStr = artwork.sizes.map { "\($0.width)x\($0.height)" }.joined(separator: ", ")
                print("      Artwork: \(sizesStr)")
            } else {
                print("      Artwork: None")
            }
            print("")
        }

    } catch {
        print("Error: \(error)")
    }
}

func testArtworkLoading(iPodPath: String) {
    print("Testing artwork loading from: \(iPodPath)")
    print(String(repeating: "=", count: 60))

    do {
        let ipod = try iPod(url: URL(fileURLWithPath: iPodPath))

        guard let trackWithArtwork = ipod.tracks.first(where: { $0.artwork != nil }),
              let artwork = trackWithArtwork.artwork else {
            print("No tracks with artwork found")
            return
        }

        print("Track: \(trackWithArtwork.displayName)")
        if let artist = trackWithArtwork.artist {
            print("Artist: \(artist)")
        }
        print("Available sizes: \(artwork.sizes.map { "\($0.width)x\($0.height)" }.joined(separator: ", "))")
        print("")

        let image = try artwork.loadImage()
        print("Loaded image: \(image.width)x\(image.height)")

        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let outputPath = desktop.appendingPathComponent("ipod_artwork_test.png")

        guard let destination = CGImageDestinationCreateWithURL(outputPath as CFURL, kUTTypePNG, 1, nil) else {
            print("Failed to create image destination")
            return
        }

        CGImageDestinationAddImage(destination, image, nil)

        if CGImageDestinationFinalize(destination) {
            print("Saved to: \(outputPath.path)")
        } else {
            print("Failed to save image")
        }

    } catch {
        print("Error: \(error)")
    }
}

func exportAllArtwork(iPodPath: String) {
    print("Exporting all artwork from: \(iPodPath)")
    print(String(repeating: "=", count: 60))

    do {
        let ipod = try iPod(url: URL(fileURLWithPath: iPodPath))

        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let outputFolder = desktop.appendingPathComponent("iPod_Artwork")

        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        print("Output folder: \(outputFolder.path)")
        print("")

        let tracksWithArtwork = ipod.tracks.filter { $0.artwork != nil }
        print("Found \(tracksWithArtwork.count) tracks with artwork")
        print("")

        var exported = 0
        var failed = 0

        for track in tracksWithArtwork {
            guard let artwork = track.artwork else { continue }

            let safeName = sanitizeFilename("\(track.artist ?? "Unknown") - \(track.displayName)")

            do {
                let image = try artwork.loadImage()
                let outputPath = outputFolder.appendingPathComponent("\(safeName).png")

                guard let destination = CGImageDestinationCreateWithURL(outputPath as CFURL, kUTTypePNG, 1, nil) else {
                    failed += 1
                    continue
                }

                CGImageDestinationAddImage(destination, image, nil)

                if CGImageDestinationFinalize(destination) {
                    exported += 1
                    print("  \(safeName) (\(image.width)x\(image.height))")
                } else {
                    failed += 1
                }
            } catch {
                failed += 1
                print("  Failed: \(safeName) - \(error)")
            }
        }

        print("")
        print("Exported: \(exported)")
        if failed > 0 {
            print("Failed: \(failed)")
        }

    } catch {
        print("Error: \(error)")
    }
}

private func sanitizeFilename(_ name: String) -> String {
    let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
    return name.components(separatedBy: invalidChars).joined(separator: "_")
}
