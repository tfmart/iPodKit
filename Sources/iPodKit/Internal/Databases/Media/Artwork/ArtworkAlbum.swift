//
//  ArtworkAlbum.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

struct ArtworkAlbum: IPKParseable, Sendable {
    public let headerLength: UInt32
    public let totalLength: UInt32
    public let artworkId: UInt32
    public let unknownValue: UInt32
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhod")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.artworkId = try Self.ArtworkId().readUInt32(from: data)
        self.unknownValue = try Self.UnknownValue().readUInt32(from: data)
    }
}

extension ArtworkAlbum {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct ArtworkId: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct UnknownValue: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
}
