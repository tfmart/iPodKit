//
//  PhotoImage.swift
//  iPodKit
//
//  Created by Tomas Martins on 24/01/26.
//

import Foundation

struct PhotoImage: IPKParseable, Sendable {
    let headerLength: UInt32
    public let totalLength: UInt32
    public let imageId: UInt32
    public let originalDate: UInt32
    public let imageSize: UInt32
    public let fileName: String?
    
    public init(from data: Data) throws {
        try Self.validateMagicNumber(from: data, expectedId: "mhii")
        
        self.headerLength = try Self.HeaderLength().readUInt32(from: data)
        self.totalLength = try Self.TotalLength().readUInt32(from: data)
        self.imageId = try Self.ImageId().readUInt32(from: data)
        self.originalDate = try Self.OriginalDate().readUInt32(from: data)
        self.imageSize = try Self.ImageSize().readUInt32(from: data)
        
        // Try to read filename if there's more data
        if Int(headerLength) < data.count {
            let nameData = data.subdata(in: Int(headerLength)..<data.count)
            self.fileName = try? nameData.readMHODString(at: 0, length: nameData.count)
        } else {
            self.fileName = nil
        }
    }
}

extension PhotoImage {
    /// File extension if available
    var fileExtension: String? {
        guard let fileName = fileName else { return nil }
        let url = URL(fileURLWithPath: fileName)
        let ext = url.pathExtension
        return ext.isEmpty ? nil : ext.lowercased()
    }
    
    /// Check if this is a JPEG image
    var isJPEG: Bool {
        return fileExtension == "jpg" || fileExtension == "jpeg"
    }
    
    /// Check if this is a PNG image
    var isPNG: Bool {
        return fileExtension == "png"
    }
}

extension PhotoImage {
    struct HeaderLength: IPKField {
        var offset: Int { 4 }
        var length: Int { 4 }
    }
    
    struct TotalLength: IPKField {
        var offset: Int { 8 }
        var length: Int { 4 }
    }
    
    struct ImageId: IPKField {
        var offset: Int { 12 }
        var length: Int { 4 }
    }
    
    struct OriginalDate: IPKField {
        var offset: Int { 16 }
        var length: Int { 4 }
    }
    
    struct ImageSize: IPKField {
        var offset: Int { 20 }
        var length: Int { 4 }
    }
}
