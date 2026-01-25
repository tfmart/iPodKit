#!/usr/bin/env swift

import Foundation
import iPodKit

// Get file path from command line arguments
guard CommandLine.arguments.count > 1 else {
    print("Usage: analyze-itunes-db [options] /path/to/iPod")
    print("")
    print("Options:")
    print("  --test-artwork    Test artwork loading")
    print("  --export-artwork  Export all artwork to Desktop")
    print("")
    print("Examples:")
    print("  analyze-itunes-db /Volumes/iPod")
    print("  analyze-itunes-db --test-artwork /Volumes/iPod")
    exit(1)
}

if CommandLine.arguments[1] == "--test-artwork" && CommandLine.arguments.count > 2 {
    testArtworkLoading(iPodPath: CommandLine.arguments[2])
    exit(0)
}

if CommandLine.arguments[1] == "--export-artwork" && CommandLine.arguments.count > 2 {
    exportAllArtwork(iPodPath: CommandLine.arguments[2])
    exit(0)
}

let iPodPath = CommandLine.arguments[1]

// Check if path exists
guard FileManager.default.fileExists(atPath: iPodPath) else {
    print("❌ Path not found: \(iPodPath)")
    print("")
    print("Try looking for iPod volumes with:")
    print("  ls /Volumes")
    exit(1)
}

analyzeEntireiPod(iPodPath: iPodPath)
