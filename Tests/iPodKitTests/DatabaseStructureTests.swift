import Testing
import Foundation
@testable import iPodKit

// MARK: - Database Structure Validation Tests

@Test func testITunesDBHeaderValidation() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    let database = reader.database
    
    // Validate main database header
    #expect(database.versionNumber > 0, "Database should have valid version")
    #expect(database.numberOfChildren >= 1, "Database should have at least one child")
    #expect(database.headerLength > 0, "Database should have valid header length")
    #expect(database.totalLength > 0, "Database should have valid total length")
    
    print("✅ iTunes DB structure validation passed")
    print("   - Version: \(database.versionNumber)")
    print("   - Children: \(database.numberOfChildren)")
    print("   - Header length: \(database.headerLength)")
}

@Test func testTrackListStructure() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    
    // Validate track list structure
    #expect(reader.trackCount > 0, "Should have tracks")
    
    let tracks = reader.tracks
    
    // Test first few tracks for valid structure
    let testCount = min(5, tracks.count)
    for i in 0..<testCount {
        let track = tracks[i]
        
        // Basic structure validation
        #expect(track.headerLength > 0, "Track should have valid header length")
        #expect(track.totalLength > 0, "Track should have valid total length")
        #expect(track.uniqueId != 0, "Track should have unique ID")
        
        // Ensure no negative values where they don't make sense
        #expect(track.length >= 0, "Track duration should not be negative")
        #expect(track.size >= 0, "Track file size should not be negative")
        #expect(track.trackNumber >= 0, "Track number should not be negative")
        #expect(track.year >= 0, "Track year should not be negative")
        #expect(track.bitrate >= 0, "Track bitrate should not be negative")
        #expect(track.playCount >= 0, "Play count should not be negative")
    }
    
    print("✅ Track list structure validation passed for \(testCount) tracks")
}

@Test func testPlaylistStructure() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    
    // Validate playlist structure
    #expect(reader.playlistCount >= 0, "Should have valid playlist count")
    
    if reader.playlistCount > 0 {
        let playlists = reader.playlists
        
        // Test first few playlists
        let testCount = min(3, playlists.count)
        for i in 0..<testCount {
            let playlist = playlists[i]
            
            // Basic structure validation
            #expect(playlist.headerLength > 0, "Playlist should have valid header length")
            #expect(playlist.totalLength > 0, "Playlist should have valid total length")
            #expect(playlist.playlistItemCount >= 0, "Playlist track count should not be negative")
            #expect(playlist.dataObjectChildCount >= 0, "Playlist data object count should not be negative")
            
            // Test master playlist flag
            if i == 0 {
                #expect(playlist.isMasterPlaylist == true, "First playlist should be master playlist")
            }
        }
        
        print("✅ Playlist structure validation passed for \(testCount) playlists")
    }
}

@Test func testArtworkDatabaseStructure() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "ArtworkDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find ArtworkDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let data = try Data(contentsOf: URL(fileURLWithPath: resourcePath))
    let artworkDB = try ArtworkDatabase(from: data)
    
    // Validate artwork database structure
    #expect(artworkDB.versionNumber > 0, "ArtworkDB should have valid version")
    #expect(artworkDB.albums.count >= 0, "Should have valid album count")
    #expect(artworkDB.images.count >= 0, "Should have valid image count")
    #expect(artworkDB.headerLength > 0, "ArtworkDB should have valid header length")
    #expect(artworkDB.totalLength > 0, "ArtworkDB should have valid total length")
    
    // Test album structure if any albums exist
    if !artworkDB.albums.isEmpty {
        let firstAlbum = artworkDB.albums[0]
        #expect(firstAlbum.headerLength > 0, "Album should have valid header")
        #expect(firstAlbum.totalLength > 0, "Album should have valid total length")
        #expect(firstAlbum.artworkId >= 0, "Album artwork ID should not be negative")
    }
    
    // Test image structure if any images exist
    if !artworkDB.images.isEmpty {
        let firstImage = artworkDB.images[0]
        #expect(firstImage.headerLength > 0, "Image should have valid header")
        #expect(firstImage.totalLength > 0, "Image should have valid total length")
        #expect(firstImage.imageSize >= 0, "Image size should not be negative")
    }
    
    print("✅ ArtworkDB structure validation passed")
    print("   - Albums: \(artworkDB.albums.count)")
    print("   - Images: \(artworkDB.images.count)")
}

// MARK: - Data Consistency Tests

@Test func testTrackDataConsistency() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    let tracks = reader.tracks
    
    // Test data consistency across tracks
    var totalDuration: UInt64 = 0
    var totalSize: UInt64 = 0
    var tracksWithMetadata = 0
    
    for track in tracks.prefix(10) { // Test first 10 tracks for performance
        totalDuration += UInt64(track.length)
        totalSize += UInt64(track.size)
        
        if track.title != nil || track.artist != nil || track.album != nil {
            tracksWithMetadata += 1
        }
        
        // Test convenience property consistency
        let calculatedDuration = Double(track.length) / 1000.0
        #expect(abs(track.durationInSeconds - calculatedDuration) < 0.001, "Duration calculation should be consistent")
        
        // Test star rating consistency
        let calculatedRating = Int(track.rating & 0xFF) / 20
        #expect(track.starRating == calculatedRating, "Star rating calculation should be consistent")
        
        // Test visibility consistency
        let calculatedVisibility = track.visible == 1
        #expect(track.isVisible == calculatedVisibility, "Visibility calculation should be consistent")
    }
    
    #expect(totalDuration > 0, "Should have calculated total duration")
    #expect(totalSize > 0, "Should have calculated total file size")
    
    print("✅ Track data consistency validated")
    print("   - Tracks with metadata: \(tracksWithMetadata)")
    print("   - Total duration: \(totalDuration)ms")
    print("   - Total size: \(totalSize) bytes")
}

@Test func testTimestampValidation() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    let tracks = reader.tracks
    
    // Test timestamp conversion for tracks with play history
    var validTimestamps = 0
    var playedTracks = 0
    
    for track in tracks.prefix(20) {
        if track.lastPlayed > 0 {
            playedTracks += 1
            
            // Test Mac epoch conversion
            let macEpochOffset: TimeInterval = 2082844800
            let unixTimestamp = TimeInterval(track.lastPlayed) - macEpochOffset
            let expectedDate = Date(timeIntervalSince1970: unixTimestamp)
            
            if let convertedDate = track.lastPlayedDate {
                #expect(abs(convertedDate.timeIntervalSince1970 - expectedDate.timeIntervalSince1970) < 1.0, 
                       "Converted date should match expected calculation")
                validTimestamps += 1
            }
        }
        
        if track.lastModified > 0 {
            // Test last modified date conversion
            if let modifiedDate = track.lastModifiedDate {
                #expect(modifiedDate.timeIntervalSince1970 > 0, "Modified date should be valid")
            }
        }
    }
    
    print("✅ Timestamp validation completed")
    print("   - Played tracks: \(playedTracks)")
    print("   - Valid timestamp conversions: \(validTimestamps)")
}

// MARK: - String Parsing Tests

@Test func testStringMetadataParsing() async throws {
    guard let resourceURL = Bundle.module.url(forResource: "iTunesDB", withExtension: nil, subdirectory: "Resources") else {
        Issue.record("Could not find iTunesDB test resource")
        return
    }
    let resourcePath = resourceURL.path
    
    let reader = try iTunesDBReader(filePath: resourcePath)
    let tracks = reader.tracks
    
    var tracksWithTitle = 0
    var tracksWithArtist = 0
    var tracksWithAlbum = 0
    var tracksWithGenre = 0
    
    for track in tracks.prefix(50) { // Test first 50 tracks
        if let title = track.title, !title.isEmpty {
            tracksWithTitle += 1
            #expect(!title.contains("\0"), "Title should not contain null characters")
        }
        
        if let artist = track.artist, !artist.isEmpty {
            tracksWithArtist += 1
            #expect(!artist.contains("\0"), "Artist should not contain null characters")
        }
        
        if let album = track.album, !album.isEmpty {
            tracksWithAlbum += 1
            #expect(!album.contains("\0"), "Album should not contain null characters")
        }
        
        if let genre = track.genre, !genre.isEmpty {
            tracksWithGenre += 1
            #expect(!genre.contains("\0"), "Genre should not contain null characters")
        }
        
        // Test display name logic
        let displayName = track.displayName
        #expect(!displayName.isEmpty, "Display name should never be empty")
        #expect(displayName != "Unknown Track" || (track.title?.isEmpty != false && track.location?.isEmpty != false), 
               "Unknown Track should only be used when no title or location available")
    }
    
    print("✅ String metadata parsing validated")
    print("   - Tracks with title: \(tracksWithTitle)")
    print("   - Tracks with artist: \(tracksWithArtist)")
    print("   - Tracks with album: \(tracksWithAlbum)")
    print("   - Tracks with genre: \(tracksWithGenre)")
}