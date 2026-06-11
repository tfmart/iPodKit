//
//  iPod+Configuration.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

extension iPod {

    /// Advanced options for reading an iPod database.
    ///
    /// The defaults are correct for the common case - reading an iPod that is
    /// plugged into this computer. Create a configuration only when you need
    /// to override them:
    ///
    /// ```swift
    /// var configuration = iPod.Configuration()
    /// configuration.timeZone = TimeZone(identifier: "Europe/Lisbon")!
    ///
    /// let ipod = try iPod(contentsOf: databaseURL, configuration: configuration)
    /// ```
    public struct Configuration: Sendable {

        /// The time zone the device's clock was set to.
        ///
        /// Binary iPod databases store dates (last played, date added, and so
        /// on) as the device's local wall-clock time without any time zone
        /// marker. iPodKit interprets those values using this time zone so
        /// that every `Date` in the public API represents the correct
        /// absolute moment in time.
        ///
        /// The default, `TimeZone.current`, is correct whenever the iPod's
        /// clock was set by syncing with a computer in the same time zone as
        /// this one. Override it when reading a database that was written in
        /// a different time zone. Has no effect on databases that store UTC
        /// timestamps (`iTunes Library.itlp`).
        public var timeZone: TimeZone

        /// Create a configuration with default options.
        public init(timeZone: TimeZone = .current) {
            self.timeZone = timeZone
        }
    }
}
