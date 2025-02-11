//
//  IPKObject.swift
//  iPodKit
//
//  Created by Tomas Martins on 10/02/25.
//

protocol IPKObject {
    var id: String { get }
    
}

extension IPKObject {
    var header: IPKObjectHeader {
        return IPKObjectHeader()
    }
    
    var totalLenght: IPKObjectTotalLenght {
        return IPKObjectTotalLenght()
    }
}
