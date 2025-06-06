//
//  File.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/02/25.
//

import Foundation

struct IPKObjectHeader: IPKField {
    var offset: Int { 4 }
    var length: Int { 4 }
}
