//
//  TimestampConversionTests.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Testing
import Foundation
@testable import iPodKit

// MARK: - Cross-Database Timestamp Consistency
//
// The reference values below were captured from a real device (iPod nano,
// UTC-3) where the same play is recorded in two databases:
//
// - Play Counts (Mac epoch, device-local wall clock): 3864048989
// - Dynamic.itdb (Apple epoch, true UTC):              802907789
//
// Both must decode to the same absolute instant: 2026-06-11 21:56:29 UTC
// (18:56:29 at UTC-3), which is Unix timestamp 1781214989.

private let deviceTimeZone = TimeZone(secondsFromGMT: -10800)!
private let expectedUnixTimestamp: TimeInterval = 1781214989

@Test func testMacTimestampDecodesWallClockTime() {
    let date = IPKTimestamp.date(fromMacTimestamp: 3864048989, in: deviceTimeZone)
    #expect(date?.timeIntervalSince1970 == expectedUnixTimestamp)
}

@Test func testAppleTimestampDecodesUTC() {
    let date = IPKTimestamp.date(fromAppleTimestamp: 802907789)
    #expect(date?.timeIntervalSince1970 == expectedUnixTimestamp)
}

@Test func testBothEpochsAgreeOnTheSameInstant() {
    let fromPlayCounts = IPKTimestamp.date(fromMacTimestamp: 3864048989, in: deviceTimeZone)
    let fromSQLiteLibrary = IPKTimestamp.date(fromAppleTimestamp: 802907789)
    #expect(fromPlayCounts == fromSQLiteLibrary)
}

@Test func testGMTMatchesRawMacEpochArithmetic() {
    // In GMT the wall clock and the instant coincide, so the conversion must
    // reduce to plain epoch arithmetic.
    let timestamp: UInt32 = 3864048989
    let date = IPKTimestamp.date(fromMacTimestamp: timestamp, in: TimeZone(secondsFromGMT: 0)!)
    #expect(date?.timeIntervalSince1970 == TimeInterval(timestamp) - 2082844800)
}

@Test func testZeroTimestampsReturnNil() {
    #expect(IPKTimestamp.date(fromMacTimestamp: 0, in: deviceTimeZone) == nil)
    #expect(IPKTimestamp.date(fromAppleTimestamp: 0) == nil)
    #expect(IPKTimestamp.date(fromAppleTimestamp: -1) == nil)
}

@Test func testDSTTransitionResolvesToCorrectOffset() {
    // 2026-07-15 12:00:00 wall clock in New York (EDT, UTC-4).
    // Mac epoch for the wall-clock reading: seconds from 1904-01-01 to
    // 2026-07-15 12:00:00 = 1784116800 (unix, naive) + 2082844800.
    let newYork = TimeZone(identifier: "America/New_York")!
    let naiveUnix: TimeInterval = 1784116800
    let macTimestamp = UInt32(naiveUnix + 2082844800)
    let date = IPKTimestamp.date(fromMacTimestamp: macTimestamp, in: newYork)
    // EDT is UTC-4, so the instant is 4 hours after the naive reading.
    #expect(date?.timeIntervalSince1970 == naiveUnix + 4 * 3600)
}
