//
//  ArtworkDecoder.swift
//  iPodKit
//
//  Created by Tomas Martins on 25/01/26.
//

import Foundation
import CoreGraphics

internal enum ArtworkDecoder {

    static func loadImage(from thumbnail: ArtworkThumbnail, iPodURL: URL) throws -> CGImage {
        let artworkPath = iPodURL.appendingPathComponent("iPod_Control/Artwork")
        let ithmbPath = artworkPath.appendingPathComponent(thumbnail.ithmbFilename)

        let fileData = try Data(contentsOf: ithmbPath)
        let offset = Int(thumbnail.ithmbOffset)
        let size = Int(thumbnail.imageSize)

        guard offset + size <= fileData.count else {
            throw IPKError.artworkNotFound
        }

        let rawData = fileData.subdata(in: offset..<(offset + size))

        return try decodeRGB565(
            data: rawData,
            width: Int(thumbnail.imageWidth),
            height: Int(thumbnail.imageHeight)
        )
    }

    private static func decodeRGB565(data: Data, width: Int, height: Int) throws -> CGImage {
        let pixelCount = width * height
        var rgbaData = [UInt8](repeating: 255, count: pixelCount * 4)

        data.withUnsafeBytes { rawBuffer in
            let pixels = rawBuffer.bindMemory(to: UInt16.self)
            for i in 0..<min(pixelCount, pixels.count) {
                let pixel = pixels[i]
                let r = UInt8((pixel >> 11) & 0x1F) << 3
                let g = UInt8((pixel >> 5) & 0x3F) << 2
                let b = UInt8(pixel & 0x1F) << 3

                rgbaData[i * 4] = r
                rgbaData[i * 4 + 1] = g
                rgbaData[i * 4 + 2] = b
                rgbaData[i * 4 + 3] = 255
            }
        }

        guard let provider = CGDataProvider(data: Data(rgbaData) as CFData),
              let image = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: width * 4,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              ) else {
            throw IPKError.artworkDecodingFailed
        }

        return image
    }
}
