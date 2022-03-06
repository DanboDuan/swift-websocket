// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import ArgumentParser
import Dispatch
import NIO
import WebSocket

final class Server: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "server",
        abstract: "websocket server"
    )

    @OptionGroup()
    var options: CommandOptions

    private enum CodingKeys: String, CodingKey {
        case options
    }

    func run() throws {
        let address: ListeningAddress
        if let path = options.path {
            address = .unixDomainSocket(path: path)
        } else {
            address = .ip(host: "localhost", port: options.port)
        }
        WebSocket.server(listen: address, configuration: Configuration(pingInterval: .seconds(10))) { _, websocket in
            print("new client connect")
            websocket.onText { _, text in
                print("recive text from client:", text)
                websocket.send(text)
            }
            websocket.onBinary { _, binary in
                var data = binary
                if let value = data.readBytes(length: data.readableBytes) {
                    print("recive binary from client:", String(bytes: value, encoding: .utf8) ?? "")
                    websocket.send(value)
                }
            }
            _ = websocket.onClose.always { _ in
                print("client close connection")
            }
        }
    }
}
