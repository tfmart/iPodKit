//
//  iTunesDBDataSet.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

/// DataSet object in iTunes database
/// 
/// Reference: http://www.ipodlinux.org/ITunesDB/#DataSet
struct iTunesDBDataSet: IPKObject {
    let id = "mhsd"
}

extension iTunesDBDataSet {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct `Type`: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
}
