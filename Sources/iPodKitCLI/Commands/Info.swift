//
//  Info.swift
//  iPodKit
//
//  Created by Claude on 11/06/26.
//

import ArgumentParser
import iPodKitCLICore

struct Info: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show summary information about an iPod."
    )

    @OptionGroup var options: GlobalOptions

    func run() throws {
        let ipod = try options.loadiPod()

        if options.json {
            print(try JSONOutput.string(InfoDTO(ipod)))
        } else {
            print(OutputFormatter.info(ipod))
        }
    }
}
