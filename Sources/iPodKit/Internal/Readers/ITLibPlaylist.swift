//
//  ITLibPlaylist.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

internal struct ITLibPlaylist: Sendable {
    let id: Int64
    let name: String
    let isMasterPlaylist: Bool
    let trackPids: [Int64]
}
