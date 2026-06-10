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
internal struct ITDBTrack: IPKParseable, Sendable {
    // Binary fields
    let headerLength: UInt32
    let totalLength: UInt32
    let numberOfStrings: UInt32
    let uniqueId: UInt32
    let visible: UInt32
    let compilationFlag: UInt8
    let rating: UInt8
    let lastModified: UInt32
    let size: UInt32
    let length: UInt32
    let trackNumber: UInt32
    let totalTracks: UInt32
    let year: UInt32
    let bitrate: UInt32
    let sampleRate: UInt32
    let volumeAdjustment: Int32
    let startTime: UInt32
    let stopTime: UInt32
    let soundCheck: UInt32
    let playCount: UInt32
    let lastPlayed: UInt32
    let discNumber: UInt32
    let totalDiscs: UInt32
    let dateAdded: UInt32
    let dbid: UInt64
    let bpm: UInt16
    let mediaType: UInt32

    // Parsed string metadata
    let title: String?
    let location: String?
    let album: String?
    let artist: String?
    let genre: String?
    let comment: String?
    let composer: String?
    let grouping: String?
    
    init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhit")

        // Parse binary fields
        self.headerLength = try Self.headerLengthField.readUInt32(from: data)
        self.totalLength = try Self.totalLengthField.readUInt32(from: data)
        self.numberOfStrings = try Self.stringsField.readUInt32(from: data)
        self.uniqueId = try Self.identifierField.readUInt32(from: data)
        self.visible = try Self.visibleField.readUInt32(from: data)
        _ = try Self.fileTypeField.readUInt32(from: data)
        self.compilationFlag = try Self.compilationFlagField.readUInt8(from: data)
        self.rating = try Self.ratingField.readUInt8(from: data)
        self.lastModified = try Self.lastModifiedField.readUInt32(from: data)
        self.size = try Self.sizeField.readUInt32(from: data)
        self.length = try Self.lengthField.readUInt32(from: data)
        self.trackNumber = try Self.trackNumberField.readUInt32(from: data)
        self.totalTracks = try Self.totalTracksField.readUInt32(from: data)
        self.year = try Self.yearField.readUInt32(from: data)
        self.bitrate = try Self.bitrateField.readUInt32(from: data)
        self.sampleRate = try Self.sampleRateField.readUInt32(from: data)
        self.volumeAdjustment = try Self.volumeAdjustmentField.readInt32(from: data)
        self.startTime = try Self.startTimeField.readUInt32(from: data)
        self.stopTime = try Self.stopTimeField.readUInt32(from: data)
        self.soundCheck = try Self.soundCheckField.readUInt32(from: data)
        self.playCount = try Self.playCountField.readUInt32(from: data)
        self.lastPlayed = try Self.lastPlayedField.readUInt32(from: data)
        self.discNumber = try Self.discNumberField.readUInt32(from: data)
        self.totalDiscs = try Self.totalDiscsField.readUInt32(from: data)
        self.dateAdded = try Self.dateAddedField.readUInt32(from: data)
        self.dbid = try Self.dbidField.readUInt64(from: data)
        self.bpm = try Self.bpmField.readUInt16(from: data)
        self.mediaType = try Self.mediaTypeField.readUInt32(from: data)

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

}

extension ITDBTrack {
    static let headerLengthField = IPKBinaryField(offset: 4, length: 4)
    static let totalLengthField = IPKBinaryField(offset: 8, length: 4)
    static let stringsField = IPKBinaryField(offset: 12, length: 4)
    static let identifierField = IPKBinaryField(offset: 16, length: 4)
    static let visibleField = IPKBinaryField(offset: 20, length: 4)
    static let fileTypeField = IPKBinaryField(offset: 24, length: 4)
    static let compilationFlagField = IPKBinaryField(offset: 30, length: 1)
    static let ratingField = IPKBinaryField(offset: 31, length: 1)
    static let lastModifiedField = IPKBinaryField(offset: 32, length: 4)
    static let sizeField = IPKBinaryField(offset: 36, length: 4)
    static let lengthField = IPKBinaryField(offset: 40, length: 4)
    static let trackNumberField = IPKBinaryField(offset: 44, length: 4)
    static let totalTracksField = IPKBinaryField(offset: 48, length: 4)
    static let yearField = IPKBinaryField(offset: 52, length: 4)
    static let bitrateField = IPKBinaryField(offset: 56, length: 4)
    static let sampleRateField = IPKBinaryField(offset: 60, length: 4)
    static let volumeAdjustmentField = IPKBinaryField(offset: 64, length: 4)
    static let startTimeField = IPKBinaryField(offset: 68, length: 4)
    static let stopTimeField = IPKBinaryField(offset: 72, length: 4)
    static let soundCheckField = IPKBinaryField(offset: 76, length: 4)
    static let playCountField = IPKBinaryField(offset: 80, length: 4)
    static let lastPlayedField = IPKBinaryField(offset: 88, length: 4)
    static let discNumberField = IPKBinaryField(offset: 92, length: 4)
    static let totalDiscsField = IPKBinaryField(offset: 96, length: 4)
    static let dateAddedField = IPKBinaryField(offset: 104, length: 4)
    static let dbidField = IPKBinaryField(offset: 112, length: 8)
    static let bpmField = IPKBinaryField(offset: 122, length: 2)
    static let mediaTypeField = IPKBinaryField(offset: 208, length: 4)
}
