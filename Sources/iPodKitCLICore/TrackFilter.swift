//
//  TrackFilter.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Foundation
import iPodKit

/// Filtering options for the `tracks` command.
///
/// All text filters are case-insensitive substring matches. `search` matches
/// against title, artist, and album. `limit` truncates after filtering.
package struct TrackFilter: Sendable {
    package var artist: String?
    package var album: String?
    package var genre: String?
    package var search: String?
    package var limit: Int?

    package init(
        artist: String? = nil,
        album: String? = nil,
        genre: String? = nil,
        search: String? = nil,
        limit: Int? = nil
    ) {
        self.artist = artist
        self.album = album
        self.genre = genre
        self.search = search
        self.limit = limit
    }

    package func apply(to tracks: [Track]) -> [Track] {
        var result = tracks

        if let artist {
            result = result.filter { contains($0.artist, artist) }
        }
        if let album {
            result = result.filter { contains($0.album, album) }
        }
        if let genre {
            result = result.filter { contains($0.genre, genre) }
        }
        if let search {
            result = result.filter {
                contains($0.title, search) || contains($0.artist, search) || contains($0.album, search)
            }
        }
        if let limit {
            result = Array(result.prefix(limit))
        }

        return result
    }

    private func contains(_ value: String?, _ needle: String) -> Bool {
        value?.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
