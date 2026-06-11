//
//  Device.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import iPodKitCLICore

struct Device: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show device details: serial, settings, sync source, radio presets, and Bluetooth pairings."
    )

    @OptionGroup var options: GlobalOptions

    func run() throws {
        let ipod = try options.loadiPod()

        if options.json {
            print(try JSONOutput.string(DeviceDTO(ipod)))
        } else {
            print(OutputFormatter.deviceDetail(ipod))
        }
    }
}
