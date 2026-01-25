//
//  iPodModel.swift
//  iPodKit
//
//  Created by Tomas Martins on 20/01/26.
//

import Foundation

/// Represents iPod hardware models and their product families.
///
/// Use this enum to identify specific iPod generations and access
/// human-readable display names. Models can be looked up by USB Product ID
/// or used directly for device-specific logic.
///
/// ## Supported Models
///
/// - iPod Classic (1st through 6th generation)
/// - iPod Mini (1st and 2nd generation)
/// - iPod Nano (1st through 7th generation)
/// - iPod Shuffle (1st through 4th generation)
public enum iPodModel: String, Codable, Sendable, CaseIterable {
    // iPod Classic
    case iPodClassicOriginal
    case iPodClassicSecondGen
    case iPodClassicThirdGen
    case iPodClassicFourthGen
    case iPodClassicFifthGen
    case iPodClassicSixthGen

    // iPod Mini
    case iPodMini

    // iPod Nano
    case iPodNanoFirstGen
    case iPodNanoSecondGen
    case iPodNanoThirdGen
    case iPodNanoFourthGen
    case iPodNanoFifthGen
    case iPodNanoSixthGen
    case iPodNanoSeventhGen

    // iPod Shuffle
    case iPodShuffleFirstGen
    case iPodShuffleSecondGen
    case iPodShuffleThirdGen
    case iPodShuffleFourthGen

    // MARK: - USB Product ID Mapping

    /// Creates an iPod model from a USB Product ID.
    ///
    /// Apple's USB Vendor ID is 0x05ac. This initializer maps the Product ID
    /// portion to specific iPod models.
    ///
    /// ```swift
    /// let model = iPodModel(usbProductID: 0x1261) // iPod classic 6th gen
    /// ```
    ///
    /// - Parameter usbProductID: The USB Product ID (without vendor ID)
    public init?(usbProductID: Int) {
        guard let model = Self.allCases.first(where: { $0.usbProductID == usbProductID }) else {
            return nil
        }
        self = model
    }

    /// The USB Product ID for this iPod model.
    ///
    /// Apple's USB Vendor ID is 0x05ac. This property returns the Product ID
    /// portion specific to each iPod model.
    public var usbProductID: Int {
        switch self {
        // iPod Classic/Original
        case .iPodClassicOriginal: return 0x1202      // 1st and 2nd generation
        case .iPodClassicSecondGen: return 0x1202     // shares ID with 1st gen
        case .iPodClassicThirdGen: return 0x1201      // 3rd generation (dock connector)
        case .iPodClassicFourthGen: return 0x1203     // 4th generation (Click Wheel)
        case .iPodClassicFifthGen: return 0x1209      // iPod with video (5th gen)
        case .iPodClassicSixthGen: return 0x1261      // iPod classic (6th gen)

        // iPod Mini
        case .iPodMini: return 0x1205                 // iPod mini (1st and 2nd gen)

        // iPod Nano
        case .iPodNanoFirstGen: return 0x120A         // iPod nano (1st gen)
        case .iPodNanoSecondGen: return 0x1260        // iPod nano (2nd gen)
        case .iPodNanoThirdGen: return 0x1262         // iPod nano (3rd gen)
        case .iPodNanoFourthGen: return 0x1263        // iPod nano (4th gen)
        case .iPodNanoFifthGen: return 0x1265         // iPod nano (5th gen)
        case .iPodNanoSixthGen: return 0x1266         // iPod nano (6th gen)
        case .iPodNanoSeventhGen: return 0x1267       // iPod nano (7th gen)

        // iPod Shuffle
        case .iPodShuffleFirstGen: return 0x1300      // iPod Shuffle 1st gen
        case .iPodShuffleSecondGen: return 0x1301     // iPod Shuffle 2nd gen
        case .iPodShuffleThirdGen: return 0x1302      // iPod Shuffle 3rd gen
        case .iPodShuffleFourthGen: return 0x1303     // iPod Shuffle 4th gen
        }
    }

    // MARK: - Display Properties

    /// Human-readable display name for the model.
    ///
    /// Returns a user-friendly name like "iPod Classic" or "iPod Nano (3rd Generation)".
    public var displayName: String {
        switch self {
        case .iPodClassicOriginal: return "iPod (1st/2nd Generation)"
        case .iPodClassicSecondGen: return "iPod (2nd Generation)"
        case .iPodClassicThirdGen: return "iPod (3rd Generation)"
        case .iPodClassicFourthGen: return "iPod (4th Generation)"
        case .iPodClassicFifthGen: return "iPod (5th Generation)"
        case .iPodClassicSixthGen: return "iPod Classic"
        case .iPodMini: return "iPod Mini"
        case .iPodNanoFirstGen: return "iPod Nano (1st Generation)"
        case .iPodNanoSecondGen: return "iPod Nano (2nd Generation)"
        case .iPodNanoThirdGen: return "iPod Nano (3rd Generation)"
        case .iPodNanoFourthGen: return "iPod Nano (4th Generation)"
        case .iPodNanoFifthGen: return "iPod Nano (5th Generation)"
        case .iPodNanoSixthGen: return "iPod Nano (6th Generation)"
        case .iPodNanoSeventhGen: return "iPod Nano (7th Generation)"
        case .iPodShuffleFirstGen: return "iPod Shuffle (1st Generation)"
        case .iPodShuffleSecondGen: return "iPod Shuffle (2nd Generation)"
        case .iPodShuffleThirdGen: return "iPod Shuffle (3rd Generation)"
        case .iPodShuffleFourthGen: return "iPod Shuffle (4th Generation)"
        }
    }

    // MARK: - Model Family

    /// The product family this model belongs to.
    public var family: Family {
        switch self {
        case .iPodClassicOriginal, .iPodClassicSecondGen, .iPodClassicThirdGen,
             .iPodClassicFourthGen, .iPodClassicFifthGen, .iPodClassicSixthGen:
            return .classic
        case .iPodMini:
            return .mini
        case .iPodNanoFirstGen, .iPodNanoSecondGen, .iPodNanoThirdGen,
             .iPodNanoFourthGen, .iPodNanoFifthGen, .iPodNanoSixthGen, .iPodNanoSeventhGen:
            return .nano
        case .iPodShuffleFirstGen, .iPodShuffleSecondGen, .iPodShuffleThirdGen, .iPodShuffleFourthGen:
            return .shuffle
        }
    }

    /// iPod product family categories.
    public enum Family: String, Codable, Sendable, CaseIterable {
        case classic
        case mini
        case nano
        case shuffle

        /// Human-readable display name for the family.
        public var displayName: String {
            switch self {
            case .classic: return "iPod Classic"
            case .mini: return "iPod Mini"
            case .nano: return "iPod Nano"
            case .shuffle: return "iPod Shuffle"
            }
        }
    }
}

// MARK: - Apple USB Constants

public extension iPodModel {
    /// Apple's USB Vendor ID (0x05ac)
    static let appleVendorID: Int = 0x05ac
}
