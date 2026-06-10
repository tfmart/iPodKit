//
//  iPodDBReader.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation
import os.log

private let optionalDatabaseLog = OSLog(subsystem: "iPodKit", category: "iPodDBReader")

/// Unified iPod Database Reader supporting all iTunes database file types.
///
/// ``iPodDBReader`` provides a comprehensive interface for reading and parsing
/// all types of iPod database files, from the main iTunesDB to specialized
/// files like Play Counts, Artwork Database, Photo Database, and iPod Shuffle files.
///
/// The reader automatically detects the database type and loads available files
/// from the provided directory or database file.
///
/// ## Usage
/// 
/// ```swift
/// let reader = try iPodDBReader(contentsOf: databaseURL)
/// 
/// print("Device Type: \(reader.deviceType)")
/// print("Loaded Files: \(reader.loadedFiles)")
/// 
/// // Access different database types
/// if let artworkDB = reader.artworkDB {
///     print("Found \(artworkDB.imageItems.count) artwork images")
/// }
/// ```
/// 
/// ## Supported File Types
/// 
/// - **Standard iPods**: iTunesDB, Play Counts, OTG Playlists, Equalizer Presets
/// - **iPod Photo**: ArtworkDB, Photo Database
/// - **iPod Shuffle**: iTunesSD, iTunesStats, iTunesShuffle, iTunesPState
/// 
/// ## Device Detection
/// 
/// The reader automatically detects device type by examining available files:
/// - Presence of iTunesSD indicates iPod Shuffle
/// - Presence of ArtworkDB/Photo Database indicates iPod Photo
/// - Standard iTunesDB indicates regular iPod
/// 
/// ## Topics
/// 
/// ### Creating a Reader
/// - ``init(iPodPath:)``
/// - ``init(filePath:fileType:)``
/// 
/// ### Device Information
/// - ``deviceType``
/// - ``deviceInfo``
/// - ``loadedFiles``
/// 
/// ### Database Access
/// - ``iTunesDB``
/// - ``playCountsDB``
/// - ``artworkDB``
/// - ``photoDB``
/// - ``shuffleDB``
/// - ``shuffleStats``
/// 
/// ### Search and Analysis
/// - ``search(_:)``
/// - ``summary``
/// - ``exportData()``
internal class iPodDBReader {
    
    // MARK: - Properties

    // Main database files
    private(set) var iTunesDB: iTunesDBReader?
    private(set) var playCountsDB: PlayCounts?
    private(set) var otgPlaylist: OTGPlaylist?
    private(set) var equalizerPresets: EqualizerPresets?
    private(set) var artworkDB: ArtworkDatabase?
    private(set) var photoDB: PhotoDatabase?

    // iPod Shuffle specific files
    private(set) var shuffleDB: iTunesSD?
    private(set) var shuffleStats: iTunesStats?
    private(set) var shuffleOrder: iTunesShuffle?
    private(set) var playbackState: iTunesPState?

    // SQLite-based iTunes Library (newer iPods)
    private(set) var iTunesLibrary: iTunesLibraryReader?

    private(set) var basePath: String
    private(set) var deviceType: iPodDeviceType
    /// Device name extracted from database files (e.g., "John's iPod")
    /// For SQLite-based iTunes Library, extracted from primary container.
    /// For binary iTunesDB, extracted from master playlist name.
    var deviceName: String? {
        return iTunesLibrary?.deviceName ?? iTunesDB?.deviceName
    }

    // MARK: - Initialization
    
    /// Initialize with a directory that contains a supported iPod database layout.
    /// - Parameter iPodPath: Path to a directory that contains database files.
    /// - Throws: Parsing or file reading errors
    init(iPodPath: String) throws {
        self.basePath = iPodPath
        self.deviceType = .unknown
        
        detectDeviceType()
        try loadDatabaseFiles()
    }

    /// Initialize with a database file or containing directory.
    /// - Parameter url: URL to a supported database file or a directory containing one.
    /// - Throws: Parsing or file reading errors.
    convenience init(contentsOf url: URL) throws {
        var isDirectory: ObjCBool = false
        let path = url.path
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw IPKParsingError.fileNotFound(path)
        }

        if isDirectory.boolValue {
            try self.init(iPodPath: path)
            return
        }

        if url.lastPathComponent == "Library.itdb" {
            try self.init(libraryPath: url)
            return
        }

        guard let fileType = DatabaseFileType(url: url) else {
            throw IPKParsingError.databaseError("Unsupported iPod database file: \(url.lastPathComponent)")
        }

        try self.init(filePath: path, fileType: fileType)
    }
    
    /// Initialize with specific database file
    /// - Parameters:
    ///   - filePath: Path to specific database file
    ///   - fileType: Type of database file
    /// - Throws: Parsing or file reading errors
    convenience init(filePath: String, fileType: DatabaseFileType) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        try self.init(iPodPath: Self.basePath(for: fileURL, fileType: fileType))

        try loadSpecificFile(at: filePath, type: fileType)
    }

    /// Initialize with a SQLite Library.itdb file.
    /// - Parameter libraryPath: URL to a Library.itdb file.
    /// - Throws: Parsing or file reading errors.
    convenience init(libraryPath: URL) throws {
        try self.init(iPodPath: Self.basePath(for: libraryPath, relativePath: "iPod_Control/iTunes/iTunes Library.itlp/Library.itdb"))

        if iTunesLibrary == nil {
            let dynamicPath = libraryPath.deletingLastPathComponent().appendingPathComponent("Dynamic.itdb")
            iTunesLibrary = try iTunesLibraryReader(libraryPath: libraryPath, dynamicPath: dynamicPath)
            deviceType = .sqliteLibrary
            loadOptionalDatabase(.artworkDB, as: ArtworkDatabase.self) { artworkDB = $0 }
        }
    }
    
    // MARK: - Private Methods
    
    private func detectDeviceType() {
        // Check for SQLite-based iTunes Library first (newer iPods like Nano 6th/7th gen)
        if iTunesLibraryReader.isSupported(iPodPath: basePath) {
            deviceType = .sqliteLibrary
            return
        }

        // Check for iPod Shuffle files
        if fileExists(for: .iTunesSD) {
            deviceType = .shuffle
            return
        }

        // Check for regular iTunesDB
        if fileExists(for: .iTunesDB) {
            // Check if it's a Photo iPod
            if fileExists(for: .artworkDB) || fileExists(for: .photoDB) {
                deviceType = .photo
            } else {
                deviceType = .standard
            }
            return
        }

        deviceType = .unknown
    }
    
    private func fileExists(for type: DatabaseFileType) -> Bool {
        return findFilePath(for: type) != nil
    }
    
    private func findFilePath(for type: DatabaseFileType) -> String? {
        for relativePath in type.standardPaths {
            let fullPath = URL(fileURLWithPath: basePath).appendingPathComponent(relativePath).path
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
        }

        for fileName in type.fileNames {
            let fullPath = URL(fileURLWithPath: basePath).appendingPathComponent(fileName).path
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
        }

        return nil
    }
    
    private func loadDatabaseFiles() throws {
        switch deviceType {
        case .standard:
            try loadStandardFiles()
        case .shuffle:
            try loadShuffleFiles()
        case .photo:
            try loadPhotoFiles()
        case .sqliteLibrary:
            try loadSQLiteLibraryFiles()
        case .unknown:
            // Try to load whatever files we can find
            try loadAvailableFiles()
        }
    }

    private func loadSQLiteLibraryFiles() throws {
        iTunesLibrary = try iTunesLibraryReader(iPodPath: basePath)

        loadOptionalDatabase(.artworkDB, as: ArtworkDatabase.self) { artworkDB = $0 }
    }

    private func loadStandardFiles() throws {
        // Load main iTunesDB
        if let path = findFilePath(for: .iTunesDB) {
            iTunesDB = try iTunesDBReader(filePath: path)
        }

        // Load optional files
        loadOptionalDatabase(.playCounts, as: PlayCounts.self) { playCountsDB = $0 }
        loadOptionalDatabase(.otgPlaylist, as: OTGPlaylist.self) { otgPlaylist = $0 }
        loadOptionalDatabase(.equalizerPresets, as: EqualizerPresets.self) { equalizerPresets = $0 }
        loadOptionalDatabase(.artworkDB, as: ArtworkDatabase.self) { artworkDB = $0 }
    }
    
    private func loadShuffleFiles() throws {
        // Load main iTunesSD
        if let path = findFilePath(for: .iTunesSD) {
            shuffleDB = try iTunesSD(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        // Load optional Shuffle files
        loadOptionalDatabase(.iTunesStats, as: iTunesStats.self) { shuffleStats = $0 }
        loadOptionalDatabase(.iTunesShuffle, as: iTunesShuffle.self) { shuffleOrder = $0 }
        loadOptionalDatabase(.iTunesPState, as: iTunesPState.self) { playbackState = $0 }
    }
    
    private func loadPhotoFiles() throws {
        // Load standard files first
        try loadStandardFiles()
        
        // Load photo-specific files
        loadOptionalDatabase(.photoDB, as: PhotoDatabase.self) { photoDB = $0 }
    }
    
    private func loadAvailableFiles() throws {
        for fileType in DatabaseFileType.allCases {
            loadOptionalFile(fileType) { path in
                try loadSpecificFile(at: path, type: fileType)
            }
        }
    }

    private func loadOptionalFile(_ type: DatabaseFileType, loader: (String) throws -> Void) {
        guard let path = findFilePath(for: type) else { return }
        
        do {
            try loader(path)
        } catch {
            os_log(
                "Could not load optional database %{public}@: %{public}@",
                log: optionalDatabaseLog,
                type: .info,
                type.rawValue,
                error.localizedDescription
            )
        }
    }

    private func loadOptionalDatabase<T: IPKParseable>(
        _ type: DatabaseFileType,
        as _: T.Type,
        assign: (T) -> Void
    ) {
        loadOptionalFile(type) { path in
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            assign(try T(from: data))
        }
    }
    
    private func loadSpecificFile(at path: String, type: DatabaseFileType) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        
        switch type {
        case .iTunesDB:
            iTunesDB = try iTunesDBReader(filePath: path)
        case .playCounts:
            playCountsDB = try PlayCounts(from: data)
        case .otgPlaylist:
            otgPlaylist = try OTGPlaylist(from: data)
        case .equalizerPresets:
            equalizerPresets = try EqualizerPresets(from: data)
        case .artworkDB:
            artworkDB = try ArtworkDatabase(from: data)
        case .photoDB:
            photoDB = try PhotoDatabase(from: data)
        case .iTunesSD:
            shuffleDB = try iTunesSD(from: data)
        case .iTunesStats:
            shuffleStats = try iTunesStats(from: data)
        case .iTunesShuffle:
            shuffleOrder = try iTunesShuffle(from: data)
        case .iTunesPState:
            playbackState = try iTunesPState(from: data)
        }
    }
}

// MARK: - Path Resolution

private extension iPodDBReader {

    static func basePath(for fileURL: URL, fileType: DatabaseFileType) -> String {
        for relativePath in fileType.standardPaths {
            if let basePath = inferredBasePath(for: fileURL, relativePath: relativePath) {
                return basePath
            }
        }

        return fileURL.deletingLastPathComponent().path
    }

    static func basePath(for fileURL: URL, relativePath: String) -> String {
        if let basePath = inferredBasePath(for: fileURL, relativePath: relativePath) {
            return basePath
        }

        return fileURL.deletingLastPathComponent().path
    }

    static func inferredBasePath(for fileURL: URL, relativePath: String) -> String? {
        let suffix = "/" + relativePath
        let path = fileURL.standardizedFileURL.path

        guard path.hasSuffix(suffix) else {
            return nil
        }

        return String(path.dropLast(suffix.count))
    }
}

// MARK: - Internal API
internal extension iPodDBReader {
    
    /// Get information about detected iPod
    var deviceInfo: [String: Any] {
        return [
            "deviceType": deviceType,
            "basePath": basePath,
            "supportedFiles": deviceType.supportedFiles,
            "loadedFiles": loadedFiles,
            "hasMainDatabase": hasMainDatabase,
            "trackCount": totalTrackCount,
            "playlistCount": totalPlaylistCount
        ]
    }
    
    /// Get list of successfully loaded database files
    var loadedFiles: [String] {
        var files: [String] = []

        if iTunesDB != nil { files.append("iTunesDB") }
        if iTunesLibrary != nil { files.append("iTunes Library (SQLite)") }
        if playCountsDB != nil { files.append("Play Counts") }
        if otgPlaylist != nil { files.append("OTG Playlist") }
        if equalizerPresets != nil { files.append("Equalizer Presets") }
        if artworkDB != nil { files.append("Artwork Database") }
        if photoDB != nil { files.append("Photo Database") }
        if shuffleDB != nil { files.append("iTunesSD") }
        if shuffleStats != nil { files.append("iTunesStats") }
        if shuffleOrder != nil { files.append("iTunesShuffle") }
        if playbackState != nil { files.append("iTunesPState") }

        return files
    }
    
    /// Check if main database is available
    var hasMainDatabase: Bool {
        return iTunesDB != nil || shuffleDB != nil || iTunesLibrary != nil
    }

    /// Get total track count from main database
    var totalTrackCount: Int {
        if let db = iTunesDB {
            return db.trackCount
        } else if let lib = iTunesLibrary {
            return lib.trackCount
        } else if let sd = shuffleDB {
            return Int(sd.numberOfTracks)
        }
        return 0
    }
    
    /// Get total playlist count
    var totalPlaylistCount: Int {
        return iTunesDB?.playlistCount ?? 0
    }
    
    /// Get comprehensive database summary
    var summary: [String: Any] {
        var summary: [String: Any] = [
            "device": deviceInfo,
            "databases": [:]
        ]
        
        var databases: [String: Any] = [:]
        
        if let db = iTunesDB {
            databases["iTunesDB"] = [
                "version": db.version,
                "tracks": db.trackCount,
                "playlists": db.playlistCount,
                "artists": db.allArtists().count,
                "albums": db.allAlbums().count,
                "genres": db.allGenres().count
            ]
        }
        
        if let pc = playCountsDB {
            databases["playCounts"] = [
                "entries": pc.entries.count,
                "playedTracks": pc.playedEntries().count
            ]
        }
        
        if let otg = otgPlaylist {
            databases["otgPlaylist"] = [
                "tracks": otg.count,
                "isEmpty": otg.isEmpty
            ]
        }
        
        if let eq = equalizerPresets {
            databases["equalizerPresets"] = [
                "presets": eq.presets.count,
                "hasPresets": eq.hasPresets
            ]
        }
        
        if let art = artworkDB {
            databases["artworkDB"] = [
                "images": art.imageItems.count
            ]
        }
        
        if let photo = photoDB {
            databases["photoDB"] = [
                "albums": photo.albums.count,
                "images": photo.images.count,
                "totalSize": photo.formattedTotalSize
            ]
        }
        
        if let sd = shuffleDB {
            databases["iTunesSD"] = [
                "version": sd.versionNumber,
                "tracks": sd.numberOfTracks,
                "totalDuration": sd.totalDurationFormatted,
                "fileTypes": sd.uniqueFileExtensions()
            ]
        }
        
        if let stats = shuffleStats {
            databases["iTunesStats"] = [
                "entries": stats.entries.count,
                "playedTracks": stats.playedTrackCount,
                "skippedTracks": stats.skippedTrackCount,
                "ratedTracks": stats.ratedTrackCount,
                "totalPlayCount": stats.totalPlayCount,
                "averageRating": stats.averageStarRating
            ]
        }
        
        if let shuffle = shuffleOrder {
            databases["iTunesShuffle"] = [
                "tracks": shuffle.count,
                "isValid": shuffle.isValid,
                "statistics": shuffle.shuffleStatistics()
            ]
        }
        
        if let state = playbackState {
            databases["iTunesPState"] = state.summary
        }
        
        summary["databases"] = databases
        
        return summary
    }
    
}
