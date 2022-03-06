// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import NIO
import NIOFoundationCompat
import NIOHTTP1
import NIOPosix
import NIOWebSocket

public final class WebSocket {
    public enum Error: Swift.Error, LocalizedError {
        case invalidResponseStatus(HTTPResponseHead)
        public var errorDescription: String? {
            return "\(self)"
        }
    }

    private let channel: WebSocketChannel
    private var onTextCallback: (WebSocket, String) -> Void
    private var onBinaryCallback: (WebSocket, ByteBuffer) -> Void
    private var frameSequence: WebSocketFrameSequence?

    public var eventLoop: EventLoop {
        return channel.eventLoop
    }

    public var isClosed: Bool {
        channel.isClosed
    }

    public var closeCode: WebSocketErrorCode? {
        return channel.closeCode
    }

    public var onClose: EventLoopFuture<Void> {
        channel.onClose
    }

    init(channel: WebSocketChannel) {
        self.channel = channel
        onTextCallback = { _, _ in }
        onBinaryCallback = { _, _ in }
    }

    public func onText(_ callback: @escaping (WebSocket, String) -> Void) {
        onTextCallback = callback
    }

    public func onBinary(_ callback: @escaping (WebSocket, ByteBuffer) -> Void) {
        onBinaryCallback = callback
    }

    @discardableResult
    public func send<S>(_ text: S) -> EventLoopFuture<Void>
        where S: Collection, S.Element == Character
    {
        return channel.send(text)
    }

    @discardableResult
    public func send(_ binary: [UInt8]) -> EventLoopFuture<Void> {
        return channel.send(binary)
    }

    @discardableResult
    public func sendPing() -> EventLoopFuture<Void> {
        return channel.sendPing()
    }

    @discardableResult
    public func send<Data>(raw data: Data,
                           opcode: WebSocketOpcode = .binary,
                           fin: Bool = true) -> EventLoopFuture<Void>
        where Data: DataProtocol
    {
        return channel.send(raw: data, opcode: opcode, fin: fin)
    }

    @discardableResult
    public func close(code: WebSocketErrorCode = .goingAway) -> EventLoopFuture<Void> {
        return channel.close(code: code)
    }

    func handle(incoming frame: WebSocketFrame) {
        switch frame.opcode {
            case .text, .binary:
                log("recive text or binary message")
                // create a new frame sequence or use existing
                var frameSequence: WebSocketFrameSequence
                if let existing = self.frameSequence {
                    frameSequence = existing
                } else {
                    frameSequence = WebSocketFrameSequence(type: frame.opcode)
                }
                // append this frame and update the sequence
                frameSequence.append(frame)
                self.frameSequence = frameSequence
            case .continuation:
                // we must have an existing sequence
                if var frameSequence = frameSequence {
                    // append this frame and update
                    frameSequence.append(frame)
                    self.frameSequence = frameSequence
                } else {
                    close(code: .protocolError)
                }
            default:
                // We ignore all other frames.
                break
        }

        // if this frame was final and we have a non-nil frame sequence,
        // output it to the websocket and clear storage
        if let frameSequence = frameSequence, frame.fin {
            switch frameSequence.type {
                case .binary:
                    onBinaryCallback(self, frameSequence.binaryBuffer)
                case .text:
                    onTextCallback(self, frameSequence.textBuffer)
                default: break
            }
            self.frameSequence = nil
        }
    }
}
