//
//  ITDBTrack.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

/// Track Item object in iTunes database.
/// 
/// ``ITDBTrack`` represents a single track record from an iTunes database file.
/// Each track contains comprehensive metadata including title, artist, album, 
/// duration, file size, play counts, ratings, and timestamps.
/// 
/// The track structure follows the iTunes database specification and uses the
/// magic number "mhit" (Music Header Item Track).
/// 
/// ## Usage
/// 
/// ```swift
/// // Parse track from binary data
/// let track = try ITDBTrack(from: trackData)
/// 
/// // Access metadata
/// print("Title: \(track.title ?? "Unknown")")
/// print("Artist: \(track.artist ?? "Unknown")")
/// print("Duration: \(track.durationFormatted)")
/// print("Play Count: \(track.playCount)")
/// print("Rating: \(track.starRating)/5 stars")
/// ```
/// 
/// ## Binary Format
/// 
/// The track record consists of:
/// 1. Fixed-size header with binary metadata
/// 2. Variable-length string data objects (mhod)
/// 
/// String metadata is stored separately and referenced by type identifiers.
/// 
/// ## Topics
/// 
/// ### Track Metadata
/// - ``title``
/// - ``artist``
/// - ``album``
/// - ``genre``
/// - ``composer``
/// - ``location``
/// 
/// ### Audio Properties
/// - ``length``
/// - ``size``
/// - ``bitrate``
/// - ``sampleRate``
/// - ``trackNumber``
/// - ``year``
/// 
/// ### User Data
/// - ``rating``
/// - ``playCount``
/// - ``lastPlayed``
/// - ``visible``
/// 
/// ### Convenience Properties
/// - ``durationInSeconds``
/// - ``durationFormatted``
/// - ``starRating``
/// - ``displayName``
/// - ``lastPlayedDate``
/// - ``fileSizeFormatted``
/// 
/// Reference: [iTunes Database Track Item Specification](http://www.ipodlinux.org/ITunesDB/#Track_Item)
struct ITDBTrack: IPKParseable, Sendable {
    // Binary fields
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let numberOfStrings: UInt32
    public let uniqueId: UInt32
    public let visible: UInt32
    public let compilationFlag: UInt8
    public let rating: UInt8
    public let lastModified: UInt32
    public let size: UInt32
    public let length: UInt32
    public let trackNumber: UInt32
    public let totalTracks: UInt32
    public let year: UInt32
    public let bitrate: UInt32
    public let sampleRate: UInt32
    public let volumeAdjustment: Int32
    public let startTime: UInt32
    public let stopTime: UInt32
    public let soundCheck: UInt32
    public let playCount: UInt32
    public let lastPlayed: UInt32
    public let discNumber: UInt32
    public let totalDiscs: UInt32
    public let dateAdded: UInt32
    public let dbid: UInt64
    public let bpm: UInt16
    public let mediaType: UInt32

    // Parsed string metadata
    public let title: String?
    public let location: String?
    public let album: String?
    public let artist: String?
    public let genre: String?
    public let comment: String?
    public let composer: String?
    public let grouping: String?
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhit")

        // Parse binary fields
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.numberOfStrings = try Self.Strings().readUInt32(from: data)
        self.uniqueId = try Self.Identifier().readUInt32(from: data)
        self.visible = try Self.Visible().readUInt32(from: data)
        _ = try Self.FileType().readUInt32(from: data)
        self.compilationFlag = try Self.CompilationFlag().readUInt8(from: data)
        self.rating = try Self.Rating().readUInt8(from: data)
        self.lastModified = try Self.LastModified().readUInt32(from: data)
        self.size = try Self.Size().readUInt32(from: data)
        self.length = try Self.Length().readUInt32(from: data)
        self.trackNumber = try Self.TrackNumber().readUInt32(from: data)
        self.totalTracks = try Self.TotalTracks().readUInt32(from: data)
        self.year = try Self.Year().readUInt32(from: data)
        self.bitrate = try Self.Bitrate().readUInt32(from: data)
        self.sampleRate = try Self.SampleRate().readUInt32(from: data)
        self.volumeAdjustment = try Self.VolumeAdjustment().readInt32(from: data)
        self.startTime = try Self.StartTime().readUInt32(from: data)
        self.stopTime = try Self.StopTime().readUInt32(from: data)
        self.soundCheck = try Self.SoundCheck().readUInt32(from: data)
        self.playCount = try Self.PlayCount().readUInt32(from: data)
        self.lastPlayed = try Self.LastPlayed().readUInt32(from: data)
        self.discNumber = try Self.DiscNumber().readUInt32(from: data)
        self.totalDiscs = try Self.TotalDiscs().readUInt32(from: data)
        self.dateAdded = try Self.DateAdded().readUInt32(from: data)
        self.dbid = try Self.DBID().readUInt64(from: data)
        self.bpm = try Self.BPM().readUInt16(from: data)
        self.mediaType = try Self.MediaType().readUInt32(from: data)

        // Parse string metadata objects
        var stringMetadata: [ITDBDataObject.TypeIdentifier: String] = [:]
        var offset = Int(headerLength)
        
        for _ in 0..<numberOfStrings {
            guard offset < data.count else { break }
            
            let mhodData = data.subdata(in: offset..<data.count)
            let mhod = try ITDBDataObject(from: mhodData)
            
            if let stringValue = mhod.stringValue {
                stringMetadata[mhod.type] = stringValue
            }
            
            offset += Int(mhod.totalLength)
        }
        
        // Assign parsed strings to properties
        self.title = stringMetadata[.title]
        self.location = stringMetadata[.location]
        self.album = stringMetadata[.album]
        self.artist = stringMetadata[.artist]
        self.genre = stringMetadata[.genre]
        self.comment = stringMetadata[.comment]
        self.composer = stringMetadata[.composer]
        self.grouping = stringMetadata[.grouping]
    }
}

// MARK: - Convenience Properties
extension ITDBTrack {
    /// Track duration in seconds
    var durationInSeconds: Double {
        return Double(length) / 1000.0
    }
    
    /// Track duration formatted as MM:SS
    var durationFormatted: String {
        let totalSeconds = Int(durationInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// File size formatted as human readable string
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    /// Whether this track is visible in the UI
    var isVisible: Bool {
        return visible == 1
    }
    
    /// Star rating (0-5)
    var starRating: Int {
        return Int(rating & 0xFF) / 20
    }
    
    /// Display name - uses title if available, otherwise filename from location
    var displayName: String {
        if let title = title, !title.isEmpty {
            return title
        }
        
        if let location = location, !location.isEmpty {
            let url = URL(fileURLWithPath: location)
            return url.deletingPathExtension().lastPathComponent
        }
        
        return "Unknown Track"
    }
    
    /// Last played date converted from Mac epoch timestamp
    var lastPlayedDate: Date? {
        guard lastPlayed > 0 else { return nil }
        // Mac epoch starts January 1, 1904 (vs Unix epoch January 1, 1970)
        let macEpochOffset: TimeInterval = 2082844800 // seconds between 1904 and 1970
        let unixTimestamp = TimeInterval(lastPlayed) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }
    
    /// Formatted last played date string
    var lastPlayedFormatted: String {
        guard let date = lastPlayedDate else { return "Never played" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Date when track was last modified
    var lastModifiedDate: Date? {
        guard lastModified > 0 else { return nil }
        let macEpochOffset: TimeInterval = 2082844800
        let unixTimestamp = TimeInterval(lastModified) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }

    /// Date when track was added to the library
    var dateAddedDate: Date? {
        guard dateAdded > 0 else { return nil }
        let macEpochOffset: TimeInterval = 2082844800
        let unixTimestamp = TimeInterval(dateAdded) - macEpochOffset
        return Date(timeIntervalSince1970: unixTimestamp)
    }

    /// Whether this track is part of a compilation album
    var isCompilation: Bool {
        compilationFlag == 1
    }

    /// Start time in seconds (custom playback start point)
    var startTimeInSeconds: TimeInterval {
        TimeInterval(startTime) / 1000.0
    }

    /// Stop time in seconds (custom playback end point, 0 means play to end)
    var stopTimeInSeconds: TimeInterval {
        TimeInterval(stopTime) / 1000.0
    }

    /// Volume adjustment in decibels (-100% to +100% maps to -255 to +255)
    var volumeAdjustmentPercent: Int {
        Int(volumeAdjustment) * 100 / 255
    }
}

extension ITDBTrack {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }

    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }

    struct Strings: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }

    struct Identifier: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }

    struct Visible: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }

    struct FileType: IPKField {
        var offset: Int { 24 }
        var length: Int { 4 }
    }

    struct CompilationFlag: IPKField {
        var offset: Int { 30 }
        var length: Int { 1 }
    }

    struct Rating: IPKField {
        var offset: Int { 31 }
        var length: Int { 1 }
    }

    struct LastModified: IPKField {
        var offset: Int { 32 }
        var length: Int { 4 }
    }

    struct Size: IPKField {
        var offset: Int { 36 }
        var length: Int { 4 }
    }

    struct Length: IPKField {
        var offset: Int { 40 }
        var length: Int { 4 }
    }

    struct TrackNumber: IPKField {
        var offset: Int { 44 }
        var length: Int { 4 }
    }

    struct TotalTracks: IPKField {
        var offset: Int { 48 }
        var length: Int { 4 }
    }

    struct Year: IPKField {
        var offset: Int { 52 }
        var length: Int { 4 }
    }

    struct Bitrate: IPKField {
        var offset: Int { 56 }
        var length: Int { 4 }
    }

    struct SampleRate: IPKField {
        var offset: Int { 60 }
        var length: Int { 4 }
    }

    struct VolumeAdjustment: IPKField {
        var offset: Int { 64 }
        var length: Int { 4 }
    }

    struct StartTime: IPKField {
        var offset: Int { 68 }
        var length: Int { 4 }
    }

    struct StopTime: IPKField {
        var offset: Int { 72 }
        var length: Int { 4 }
    }

    struct SoundCheck: IPKField {
        var offset: Int { 76 }
        var length: Int { 4 }
    }

    struct PlayCount: IPKField {
        var offset: Int { 80 }
        var length: Int { 4 }
    }

    struct LastPlayed: IPKField {
        var offset: Int { 88 }
        var length: Int { 4 }
    }

    struct DiscNumber: IPKField {
        var offset: Int { 92 }
        var length: Int { 4 }
    }

    struct TotalDiscs: IPKField {
        var offset: Int { 96 }
        var length: Int { 4 }
    }

    struct DateAdded: IPKField {
        var offset: Int { 104 }
        var length: Int { 4 }
    }

    struct DBID: IPKField {
        var offset: Int { 112 }
        var length: Int { 8 }
    }

    struct BPM: IPKField {
        var offset: Int { 122 }
        var length: Int { 2 }
    }

    struct MediaType: IPKField {
        var offset: Int { 208 }
        var length: Int { 4 }
    }
}
