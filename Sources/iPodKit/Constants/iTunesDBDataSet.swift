//
//  iTunesDBDataSet.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

struct iTunesDBDataSet: IPKObject {
    let id = "mhsd"
}

extension iTunesDBDataSet {
    struct `Type`: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}
