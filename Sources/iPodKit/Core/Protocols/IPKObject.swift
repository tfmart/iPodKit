//
//  IPKObject.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

import Foundation

protocol IPKObject {
    var id: String { get }
}

protocol IPKParseable: IPKObject {
    init(from data: Data) throws
}

extension IPKObject {
    var header: IPKObjectHeader {
        return IPKObjectHeader()
    }
    
    var totalLength: IPKObjectTotalLength {
        return IPKObjectTotalLength()
    }
    
    static func validateMagicNumber(from data: Data, expectedId: String) throws {
        guard data.count >= 4 else {
            throw IPKError.insufficientData
        }
        
        let magicNumber = try data.readString(at: 0, length: 4)
        guard magicNumber == expectedId else {
            throw IPKError.invalidMagicNumber(expected: expectedId, found: magicNumber)
        }
    }
}
