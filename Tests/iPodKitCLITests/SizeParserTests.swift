//
//  SizeParserTests.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import Testing
import iPodKit
import iPodKitCLICore

@Test func testParsesValidSize() {
    #expect(SizeParser.parse("140x140") == Artwork.Size(width: 140, height: 140))
    #expect(SizeParser.parse("56X56") == Artwork.Size(width: 56, height: 56))
}

@Test func testRejectsInvalidSizes() {
    #expect(SizeParser.parse("140") == nil)
    #expect(SizeParser.parse("140x") == nil)
    #expect(SizeParser.parse("x140") == nil)
    #expect(SizeParser.parse("140x140x140") == nil)
    #expect(SizeParser.parse("0x140") == nil)
    #expect(SizeParser.parse("-1x140") == nil)
    #expect(SizeParser.parse("axb") == nil)
    #expect(SizeParser.parse("") == nil)
}
