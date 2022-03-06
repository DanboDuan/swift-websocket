// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import ArgumentParser
import Foundation
import NIO
import WebSocket

final class Client: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "client",
        abstract: "websocket client"
    )

    @OptionGroup()
    var options: CommandOptions

    private enum CodingKeys: String, CodingKey {
        case options
    }

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func run() throws {
        encoder.outputFormatting = .prettyPrinted.union(.sortedKeys).union(.withoutEscapingSlashes)
        let address: ServerAddress
        if let path = options.path {
            address = .unixDomainSocket(path: path)
        } else {
            address = .URL(URL: URL(string: "ws://127.0.0.1:\(options.port)")!)
        }
        if let websocket = WebSocket.client(connect: address, configuration: Configuration(pingInterval: .seconds(10))) {
            websocket.onText { _, text in
                print("recive text from server:", text)
            }
            websocket.onBinary { _, binary in
                var data = binary
                if let value = data.readBytes(length: data.readableBytes) {
                    print("recive binary from client:", String(bytes: value, encoding: .utf8) ?? "")
                }
            }

            websocket.send("hello test")
            websocket.send([UInt8]("hello test".utf8))
            try? websocket.onClose.wait()
        }
    }
}
