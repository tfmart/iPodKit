//
//  iPodLocator.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation

/// Finds mounted iPod volumes when no path is given.
package enum iPodLocator {

    /// Volumes under `/Volumes` containing an `iPod_Control` directory.
    package static func detectVolumes() -> [URL] {
        #if os(macOS)
        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        let fileManager = FileManager.default

        guard let volumes = try? fileManager.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return volumes.filter { volume in
            var isDirectory: ObjCBool = false
            let controlPath = volume.appendingPathComponent("iPod_Control").path
            return fileManager.fileExists(atPath: controlPath, isDirectory: &isDirectory)
                && isDirectory.boolValue
        }
        .sorted { $0.path < $1.path }
        #else
        return []
        #endif
    }
}
