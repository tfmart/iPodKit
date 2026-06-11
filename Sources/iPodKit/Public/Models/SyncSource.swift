//
//  SyncSource.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation

/// The iTunes library this iPod last synced with.
///
/// iTunes records the library owner's user name and the computer name on the
/// device every time it syncs.
///
/// ```swift
/// if let source = ipod.syncSource {
///     print("Synced with \(source.computerName ?? "unknown computer")")
/// }
/// ```
public struct SyncSource: Sendable, Hashable {

    /// User name of the iTunes library owner (e.g., "John Appleseed").
    public let userName: String?

    /// Name of the computer the iPod last synced with (e.g., "John's MacBook Pro").
    public let computerName: String?

    internal init(userName: String?, computerName: String?) {
        self.userName = userName
        self.computerName = computerName
    }
}
