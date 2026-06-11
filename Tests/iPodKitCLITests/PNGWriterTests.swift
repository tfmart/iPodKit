//
//  PNGWriterTests.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Testing
import Foundation
import CoreGraphics
import iPodKitCLICore

@Test func testWritesValidPNG() throws {
    let context = try #require(CGContext(
        data: nil,
        width: 2,
        height: 2,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    let image = try #require(context.makeImage())

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ipodkit-pngwriter-test-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }

    try PNGWriter.write(image, to: url)

    let data = try Data(contentsOf: url)
    let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
    #expect(Array(data.prefix(4)) == pngMagic)
}

@Test func testWriteToInvalidPathThrows() {
    let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let image = context.makeImage()!

    let url = URL(fileURLWithPath: "/nonexistent-directory/artwork.png")
    #expect(throws: Error.self) {
        try PNGWriter.write(image, to: url)
    }
}
