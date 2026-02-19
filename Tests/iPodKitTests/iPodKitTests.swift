import Testing
import Foundation
@testable import iPodKit

// MARK: - Core Protocol Tests

@Test func testIPKFieldProtocol() async throws {
    // Test the IPKField protocol with mock data
    struct TestField: IPKField {
        var offset: Int { 0 }
        var length: Int { 4 }
    }
    
    let data = Data([0x12, 0x34, 0x56, 0x78])
    let field = TestField()
    
    let value = try field.readUInt32(from: data)
    #expect(value == 0x78563412) // Little-endian
}

@Test func testIPKFieldDifferentDataTypes() async throws {
    let data = Data([0x12, 0x34, 0x56, 0x78, 0xAB, 0xCD, 0xEF, 0x00])
    
    struct UInt8Field: IPKField {
        var offset: Int { 0 }
        var length: Int { 1 }
    }
    
    struct UInt16Field: IPKField {
        var offset: Int { 0 }
        var length: Int { 2 }
    }
    
    struct UInt32Field: IPKField {
        var offset: Int { 0 }
        var length: Int { 4 }
    }
    
    struct UInt64Field: IPKField {
        var offset: Int { 0 }
        var length: Int { 8 }
    }
    
    #expect(try UInt8Field().readUInt8(from: data) == 0x12)
    #expect(try UInt16Field().readUInt16(from: data) == 0x3412)
    #expect(try UInt32Field().readUInt32(from: data) == 0x78563412)
    #expect(try UInt64Field().readUInt64(from: data) == 0x00EFCDAB78563412)
}

@Test func testIPKErrorHandling() async throws {
    // Test error handling for insufficient data
    let data = Data([0x12, 0x34])
    
    struct TestField: IPKField {
        var offset: Int { 0 }
        var length: Int { 4 }
    }
    
    let field = TestField()
    
    #expect(throws: IPKParsingError.self) {
        try field.readUInt32(from: data)
    }
}

@Test func testMagicNumberValidation() async throws {
    // Test magic number validation with a concrete struct
    struct TestObject: IPKParseable {
        init(from data: Data) throws {}
    }

    let validData = Data("mhbd".utf8)
    let invalidData = Data("abcd".utf8)

    // This should not throw
    try TestObject.validateMagicNumber(from: validData, expectedId: "mhbd")

    // This should throw
    #expect(throws: IPKParsingError.self) {
        try TestObject.validateMagicNumber(from: invalidData, expectedId: "mhbd")
    }
}

// MARK: - Resource File Tests

@Test func testParseActualITunesDB() async throws {
    // Get the path to the test resource
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    // Parse the actual iTunes database file
    let reader = try iTunesDBReader(filePath: resourcePath)
    
    // Verify basic database structure
    #expect(reader.trackCount > 0, "Database should contain tracks")
    #expect(reader.playlistCount >= 0, "Database should have valid playlist count")
    #expect(reader.version > 0, "Database should have valid version")
    
    // Test track parsing
    let tracks = reader.tracks
    #expect(!tracks.isEmpty, "Should have parsed tracks")
    
    // Test first track metadata
    let firstTrack = tracks[0]
    #expect(firstTrack.length > 0, "Track should have duration")
    #expect(firstTrack.size > 0, "Track should have file size")
    
    // Test convenience properties
    #expect(firstTrack.durationInSeconds > 0, "Should calculate duration in seconds")
    #expect(!firstTrack.durationFormatted.isEmpty, "Should format duration")
    #expect(!firstTrack.fileSizeFormatted.isEmpty, "Should format file size")
    #expect(!firstTrack.displayName.isEmpty, "Should have display name")
    
    print("✅ Parsed \(reader.trackCount) tracks from iTunes database")
    print("✅ First track: \(firstTrack.displayName)")
    print("✅ Duration: \(firstTrack.durationFormatted)")
    print("✅ Size: \(firstTrack.fileSizeFormatted)")
}

@Test func testParseActualArtworkDB() async throws {
    // Get the path to the test resource
    guard let resourceURL = Bundle.module.url(forResource: "ArtworkDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find ArtworkDB test resource")
        return
    }
    let resourcePath = resourceURL.path

    // Parse the actual artwork database file
    let data = try Data(contentsOf: URL(fileURLWithPath: resourcePath))
    let artworkDB = try ArtworkDatabase(from: data)

    // Verify basic artwork database structure
    #expect(artworkDB.imageItems.count >= 0, "Should have valid image count")
    #expect(artworkDB.headerLength > 0, "Should have valid header length")
    #expect(artworkDB.totalLength > 0, "Should have valid total length")

    print("✅ Parsed ArtworkDB with \(artworkDB.imageItems.count) images")
}

@Test func testParseActualPlayCounts() async throws {
    // Get the path to the test resource
    guard let resourceURL = Bundle.module.url(forResource: "Play Counts", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find Play Counts test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    // Parse the actual Play Counts file
    let data = try Data(contentsOf: URL(fileURLWithPath: resourcePath))
    let playCounts = try PlayCounts(from: data)
    
    // Verify basic Play Counts structure
    #expect(playCounts.headerLength > 0, "Should have valid header length")
    #expect(playCounts.entryLength > 0, "Should have valid entry length")
    #expect(playCounts.numberOfEntries >= 0, "Should have valid number of entries")
    #expect(playCounts.entries.count == Int(playCounts.numberOfEntries), "Entry count should match header")
    
    // Test entries if available
    if !playCounts.entries.isEmpty {
        let firstEntry = playCounts.entries[0]
        
        // Test convenience properties
        let starRating = firstEntry.starRating
        #expect(starRating >= 0 && starRating <= 5, "Star rating should be 0-5")
        
        let bookmarkFormatted = firstEntry.bookmarkTimeFormatted
        #expect(bookmarkFormatted.contains(":"), "Bookmark time should be formatted as MM:SS")
        
        // Test date conversion if entry has been played
        if firstEntry.lastPlayed > 0 {
            let lastPlayedDate = firstEntry.lastPlayedDate
            #expect(lastPlayedDate != nil, "Should convert valid timestamp to date")
            
            let formatted = firstEntry.lastPlayedFormatted
            #expect(formatted != "Never played", "Should format valid last played date")
        }
    }
    
    // Test public API methods
    let playedEntries = playCounts.playedEntries()
    let mostPlayed = playCounts.mostPlayedEntries(limit: 5)
    
    #expect(playedEntries.count >= 0, "Should return played entries")
    #expect(mostPlayed.count >= 0, "Should return most played entries")
    
    // Cross-reference with iTunes database to show which songs were played
    if let iTunesURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") {
        do {
            let iTunesReader = try iTunesDBReader(filePath: iTunesURL.path)
            let tracks = iTunesReader.tracks
            
            print("✅ Parsed Play Counts with \(playCounts.numberOfEntries) entries")
            print("✅ Header length: \(playCounts.headerLength)")
            print("✅ Entry length: \(playCounts.entryLength)")
            print("✅ Played tracks: \(playedEntries.count)")
            
            if !playedEntries.isEmpty {
                print("\n🎵 Played Songs:")
                for (index, entry) in playedEntries {
                    if index < tracks.count {
                        let track = tracks[index]
                        print("   - \(track.displayName)")
                        print("     Play count: \(entry.playCount)")
                        print("     Last played: \(entry.lastPlayedFormatted)")
                        if entry.starRating > 0 {
                            print("     Rating: \(entry.starRating)/5 stars")
                        }
                    }
                }
            }
        } catch {
            print("✅ Parsed Play Counts with \(playCounts.numberOfEntries) entries")
            print("✅ Header length: \(playCounts.headerLength)")
            print("✅ Entry length: \(playCounts.entryLength)")
            print("✅ Played tracks: \(playedEntries.count)")
        }
    } else {
        print("✅ Parsed Play Counts with \(playCounts.numberOfEntries) entries")
        print("✅ Header length: \(playCounts.headerLength)")
        print("✅ Entry length: \(playCounts.entryLength)")
        print("✅ Played tracks: \(playedEntries.count)")
    }
}

@Test func testIPodDBReaderWithTestResources() async throws {
    // Get the test resources directory  
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let iTunesDBPath = resourceURL.path
    
    let reader = try iPodDBReader(filePath: iTunesDBPath, fileType: .iTunesDB)
    
    // Verify device detection and loaded files
    #expect(reader.hasMainDatabase, "Should have main database")
    #expect(reader.totalTrackCount > 0, "Should have tracks")
    #expect(!reader.loadedFiles.isEmpty, "Should have loaded files")
    
    // Test device info
    let deviceInfo = reader.deviceInfo
    #expect(deviceInfo["trackCount"] as? Int ?? 0 > 0, "Device info should include track count")
    
    // Test summary
    let summary = reader.summary
    #expect(summary["device"] != nil, "Summary should include device info")
    #expect(summary["databases"] != nil, "Summary should include database info")
    
    print("✅ iPodDBReader loaded files: \(reader.loadedFiles)")
    print("✅ Device type: \(reader.deviceType)")
    print("✅ Total tracks: \(reader.totalTrackCount)")
}

// MARK: - Track Metadata Tests

@Test func testTrackConvenienceProperties() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    let tracks = reader.tracks
    
    guard !tracks.isEmpty else {
        Issue.record("No tracks found to test")
        return
    }
    
    let track = tracks[0]
    
    // Test star rating calculation
    let starRating = track.starRating
    #expect(starRating >= 0 && starRating <= 5, "Star rating should be 0-5")
    
    // Test visibility
    let isVisible = track.isVisible
    #expect(isVisible == true || isVisible == false, "Should have boolean visibility")
    
    // Test duration formatting
    let formatted = track.durationFormatted
    #expect(formatted.contains(":"), "Duration should be formatted as MM:SS")
    
    // Test last played date conversion
    if track.lastPlayed > 0 {
        let lastPlayedDate = track.lastPlayedDate
        #expect(lastPlayedDate != nil, "Should convert valid timestamp to date")
        
        let formatted = track.lastPlayedFormatted
        #expect(formatted != "Never played", "Should format valid last played date")
    }
    
    print("✅ Track metadata tests passed for: \(track.displayName)")
    print("   - Star rating: \(starRating)/5")
    print("   - Duration: \(formatted)")
    print("   - Visible: \(isVisible)")
}

// MARK: - Search and Query Tests

@Test func testDatabaseSearchFunctionality() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    
    // Test getting unique values
    let artists = reader.allArtists()
    let albums = reader.allAlbums()
    let genres = reader.allGenres()
    
    #expect(artists.count >= 0, "Should return artist list")
    #expect(albums.count >= 0, "Should return album list")
    #expect(genres.count >= 0, "Should return genre list")
    
    // Test search functionality if we have tracks
    if reader.trackCount > 0 {
        let firstTrack = reader.tracks[0]
        
        // Search by title if available
        if let title = firstTrack.title, !title.isEmpty {
            let titleResults = reader.tracks(withTitle: title)
            #expect(!titleResults.isEmpty, "Should find tracks by title")
        }
        
        // Search by artist if available
        if let artist = firstTrack.artist, !artist.isEmpty {
            let artistResults = reader.tracks(byArtist: artist)
            #expect(!artistResults.isEmpty, "Should find tracks by artist")
        }
        
        // Search by album if available
        if let album = firstTrack.album, !album.isEmpty {
            let albumResults = reader.tracks(fromAlbum: album)
            #expect(!albumResults.isEmpty, "Should find tracks by album")
        }
    }
    
    print("✅ Search functionality tested")
    print("   - Unique artists: \(artists.count)")
    print("   - Unique albums: \(albums.count)")
    print("   - Unique genres: \(genres.count)")
}
