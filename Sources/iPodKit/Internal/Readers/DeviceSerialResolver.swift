//
//  DeviceSerialResolver.swift
//  iPodKit
//
//  Created by Tomas Martins on 11/06/26.
//

import Foundation
#if os(macOS)
import IOKit
#endif

/// Resolves the hardware serial number of a mounted iPod.
///
/// The Apple serial number is not stored on the iPod's data partition. It is
/// resolved in two steps, both best-effort:
///
/// 1. Walk the IORegistry from the volume's BSD device up to the USB device
///    to read its USB serial string (the iPod's GUID, e.g. `000A2700247C5416`).
/// 2. Look the GUID up in iTunes/Finder's device registry at
///    `~/Library/Preferences/com.apple.iPod.plist`, which caches the Apple
///    serial number for every iPod that has been connected.
///
/// Both steps only work on macOS with the device plugged in; everywhere else
/// the resolver returns `nil`.
internal enum DeviceSerialResolver {

    /// Resolve the Apple serial number for the iPod volume at `url`.
    static func serialNumber(forVolumeAt url: URL) -> String? {
        guard let guid = usbSerialNumber(forVolumeAt: url) else { return nil }
        return appleSerialNumber(forUSBSerial: guid)
    }

    // MARK: - USB GUID

    /// Read the USB serial string (iPod GUID) for the device backing a volume.
    static func usbSerialNumber(forVolumeAt url: URL) -> String? {
        #if os(macOS)
        var fs = statfs()
        guard statfs(url.path, &fs) == 0 else { return nil }
        let mountedFrom = withUnsafePointer(to: &fs.f_mntfromname) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { String(cString: $0) }
        }
        guard mountedFrom.hasPrefix("/dev/") else { return nil }
        let bsdName = String(mountedFrom.dropFirst("/dev/".count))

        // 0 == MACH_PORT_NULL selects the default master port on all macOS versions.
        var entry = IOServiceGetMatchingService(0, IOBSDNameMatching(0, 0, bsdName))
        while entry != 0 {
            for key in ["USB Serial Number", "kUSBSerialNumberString"] {
                if let value = IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0),
                   let serial = value.takeRetainedValue() as? String {
                    IOObjectRelease(entry)
                    return serial
                }
            }
            var parent: io_registry_entry_t = 0
            let result = IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent)
            IOObjectRelease(entry)
            entry = result == KERN_SUCCESS ? parent : 0
        }
        return nil
        #else
        return nil
        #endif
    }

    // MARK: - Apple Serial Lookup

    /// Look up the Apple serial number for a USB GUID in iTunes/Finder's
    /// cached device registry.
    static func appleSerialNumber(forUSBSerial guid: String, registryURL: URL? = nil) -> String? {
        let plistURL = registryURL ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.apple.iPod.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let devices = plist["Devices"] as? [String: Any] else {
            return nil
        }

        if let device = devices[guid] as? [String: Any],
           let serial = device["Serial Number"] as? String {
            return serial
        }

        // iPods report slightly different GUID variants depending on the USB
        // mode (one byte in the middle differs), so fall back to matching the
        // outer hex digits.
        guard guid.count >= 12 else { return nil }
        let prefix = guid.prefix(6)
        let suffix = guid.suffix(6)
        for (key, value) in devices {
            guard key.count == guid.count,
                  key.hasPrefix(prefix),
                  key.hasSuffix(suffix),
                  let device = value as? [String: Any],
                  (device["Device Class"] as? String) == "iPod",
                  let serial = device["Serial Number"] as? String else {
                continue
            }
            return serial
        }
        return nil
    }
}
