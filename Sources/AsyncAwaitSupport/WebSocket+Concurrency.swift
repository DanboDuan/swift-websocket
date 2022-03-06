// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

#if compiler(>=5.5) && canImport(_Concurrency)
    import Foundation
    import NIOCore
    import NIOWebSocket
    import WebSocket

    @available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
    public extension WebSocket {
        func send<S>(_ text: S) async throws
            where S: Collection, S.Element == Character {
            return try await send(text).get()
        }

        func send(_ binary: [UInt8]) async throws {
            return try await send(binary).get()
        }

        func send<Data>(raw data: Data,
                        opcode: WebSocketOpcode,
                        fin: Bool = true) async throws
            where Data: DataProtocol {
            return try await send(raw: data, opcode: opcode, fin: fin).get()
        }

        func close(code: WebSocketErrorCode = .goingAway) async throws {
            try await close(code: code).get()
        }

        func sendPing() async throws {
            return try await sendPing().get()
        }

        func onText(_ callback: @escaping (WebSocket, String) async -> Void) {
            onText { socket, text in
                Task {
                    await callback(socket, text)
                }
            }
        }

        func onBinary(_ callback: @escaping (WebSocket, ByteBuffer) async -> Void) {
            onBinary { socket, binary in
                Task {
                    await callback(socket, binary)
                }
            }
        }
    }
#endif
