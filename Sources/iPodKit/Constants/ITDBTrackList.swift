//
//  ITDBTrackList.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

struct ITDBTrackList: IPKObject {
    let id: String = "mhlt"
}

extension ITDBTrackList {
    struct NumberOfSongs: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
}
