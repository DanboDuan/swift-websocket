// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import ArgumentParser
import Foundation
import WebSocket

final class Main: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "websocket",
        abstract: "websocket client & server",
        version: "1.0.0",
        subcommands: [
            Client.self,
            Server.self,
        ]
    )

    @OptionGroup()
    var options: CommandOptions

    func run() throws {}
}

WebSocketLogger.shared.enable = true
Main.main()
