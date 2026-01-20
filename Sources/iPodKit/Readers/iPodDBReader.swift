//
//  iPodDBReader.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Unified iPod Database Reader supporting all iTunes database file types.
/// 
/// ``iPodDBReader`` provides a comprehensive interface for reading and parsing
/// all types of iPod database files, from the main iTunesDB to specialized
/// files like Play Counts, Artwork Database, Photo Database, and iPod Shuffle files.
/// 
/// The reader automatically detects the iPod device type and loads all available
/// database files from the iPod directory structure.
/// 
/// ## Usage
/// 
/// ```swift
/// // Parse entire iPod directory with auto-detection
/// let reader = try iPodDBReader(iPodPath: "/Volumes/iPod")
/// 
/// print("Device Type: \(reader.deviceType)")
/// print("Loaded Files: \(reader.loadedFiles)")
/// 
/// // Access different database types
/// if let artworkDB = reader.artworkDB {
///     print("Found \(artworkDB.images.count) artwork images")
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
public class iPodDBReader {
    
    // MARK: - Properties

    // Main database files
    public private(set) var iTunesDB: iTunesDBReader?
    public private(set) var playCountsDB: PlayCounts?
    public private(set) var otgPlaylist: OTGPlaylist?
    public private(set) var equalizerPresets: EqualizerPresets?
    public private(set) var artworkDB: ArtworkDatabase?
    public private(set) var photoDB: PhotoDatabase?

    // iPod Shuffle specific files
    public private(set) var shuffleDB: iTunesSD?
    public private(set) var shuffleStats: iTunesStats?
    public private(set) var shuffleOrder: iTunesShuffle?
    public private(set) var playbackState: iTunesPState?

    // SQLite-based iTunes Library (newer iPods)
    public private(set) var iTunesLibrary: iTunesLibraryReader?

    public private(set) var basePath: String
    public private(set) var deviceType: iPodDeviceType
    
    // MARK: - Device Type Detection

    public enum iPodDeviceType {
        case standard       // Regular iPod with iTunesDB
        case shuffle        // iPod Shuffle with iTunesSD
        case photo          // iPod Photo with artwork support
        case sqliteLibrary  // Newer iPods with SQLite-based iTunes Library
        case unknown

        var supportedFiles: [String] {
            switch self {
            case .standard:
                return ["iTunesDB", "Play Counts", "OTG Playlist File", "Equalizer Presets"]
            case .shuffle:
                return ["iTunesSD", "iTunesStats", "iTunesShuffle", "iTunesPState"]
            case .photo:
                return ["iTunesDB", "Play Counts", "OTG Playlist File", "ArtworkDB", "Photo Database"]
            case .sqliteLibrary:
                return ["Library.itdb", "Dynamic.itdb", "Locations.itdb", "Genius.itdb", "Extras.itdb"]
            case .unknown:
                return []
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with iPod root directory path
    /// - Parameter iPodPath: Path to iPod root directory
    /// - Throws: Parsing or file reading errors
    public init(iPodPath: String) throws {
        self.basePath = iPodPath
        self.deviceType = .unknown
        
        detectDeviceType()
        try loadDatabaseFiles()
    }
    
    /// Initialize with specific database file
    /// - Parameters:
    ///   - filePath: Path to specific database file
    ///   - fileType: Type of database file
    /// - Throws: Parsing or file reading errors
    public convenience init(filePath: String, fileType: DatabaseFileType) throws {
        let directoryPath = URL(fileURLWithPath: filePath).deletingLastPathComponent().path
        try self.init(iPodPath: directoryPath)
        
        // Load the specific file
        try loadSpecificFile(at: filePath, type: fileType)
    }
    
    // MARK: - Database File Types
    
    public enum DatabaseFileType: String, CaseIterable {
        case iTunesDB = "iTunesDB"
        case playCounts = "Play Counts"
        case otgPlaylist = "OTG Playlist File"
        case equalizerPresets = "Equalizer Presets"
        case artworkDB = "ArtworkDB"
        case photoDB = "Photo Database"
        case iTunesSD = "iTunesSD"
        case iTunesStats = "iTunesStats"
        case iTunesShuffle = "iTunesShuffle"
        case iTunesPState = "iTunesPState"
        
        var standardPaths: [String] {
            switch self {
            case .iTunesDB:
                return ["iPod_Control/iTunes/iTunesDB"]
            case .playCounts:
                return ["iPod_Control/iTunes/Play Counts"]
            case .otgPlaylist:
                return ["iPod_Control/iTunes/OTG Playlist File"]
            case .equalizerPresets:
                return ["iPod_Control/iTunes/Equalizer Presets"]
            case .artworkDB:
                return ["iPod_Control/Artwork/ArtworkDB"]
            case .photoDB:
                return ["Photos/Photo Database"]
            case .iTunesSD:
                return ["iTunesSD"]
            case .iTunesStats:
                return ["iTunesStats"]
            case .iTunesShuffle:
                return ["iTunesShuffle"]
            case .iTunesPState:
                return ["iTunesPState"]
            }
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
    }
    
    private func loadStandardFiles() throws {
        // Load main iTunesDB
        if let path = findFilePath(for: .iTunesDB) {
            iTunesDB = try iTunesDBReader(filePath: path)
        }
        
        // Load optional files
        loadOptionalFile(.playCounts) { path in
            playCountsDB = try PlayCounts(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        loadOptionalFile(.otgPlaylist) { path in
            otgPlaylist = try OTGPlaylist(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        loadOptionalFile(.equalizerPresets) { path in
            equalizerPresets = try EqualizerPresets(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
    }
    
    private func loadShuffleFiles() throws {
        // Load main iTunesSD
        if let path = findFilePath(for: .iTunesSD) {
            shuffleDB = try iTunesSD(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        // Load optional Shuffle files
        loadOptionalFile(.iTunesStats) { path in
            shuffleStats = try iTunesStats(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        loadOptionalFile(.iTunesShuffle) { path in
            shuffleOrder = try iTunesShuffle(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        loadOptionalFile(.iTunesPState) { path in
            playbackState = try iTunesPState(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
    }
    
    private func loadPhotoFiles() throws {
        // Load standard files first
        try loadStandardFiles()
        
        // Load photo-specific files
        loadOptionalFile(.artworkDB) { path in
            artworkDB = try ArtworkDatabase(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
        
        loadOptionalFile(.photoDB) { path in
            photoDB = try PhotoDatabase(from: Data(contentsOf: URL(fileURLWithPath: path)))
        }
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
            // Optionally log the error, but don't fail the entire initialization
            print("Warning: Failed to load \(type.rawValue): \(error)")
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

// MARK: - Public API
public extension iPodDBReader {
    
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
                "albums": art.albums.count,
                "images": art.images.count,
                "totalSize": art.formattedTotalSize
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
    
    /// Search across all available databases
    /// - Parameter query: Search query
    /// - Returns: Dictionary of search results by database type
    func search(_ query: String) -> [String: Any] {
        var results: [String: Any] = [:]
        
        if let db = iTunesDB {
            let tracks = db.tracks(withTitle: query) + 
                        db.tracks(byArtist: query) + 
                        db.tracks(fromAlbum: query)
            if !tracks.isEmpty {
                results["iTunesDB"] = tracks.map { $0.displayName }
            }
        }
        
        if let photo = photoDB {
            if let album = photo.album(withName: query) {
                results["photoAlbums"] = [album.displayName]
            }
        }
        
        if let eq = equalizerPresets {
            if let preset = eq.preset(withName: query) {
                results["equalizerPresets"] = [preset.displayName]
            }
        }
        
        return results
    }
    
    /// Export database information to dictionary for serialization
    /// - Returns: Complete database export
    func exportData() -> [String: Any] {
        return summary
    }
}
