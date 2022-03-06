// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


import Foundation
import NIOFoundationCompat
import NIOWebSocket

final class WebSocketChannel {
    let channel: Channel
    let type: PeerType
    var waitingForClose: Bool

    var eventLoop: EventLoop {
        return channel.eventLoop
    }

    var isClosed: Bool {
        !channel.isActive
    }

    var closeCode: WebSocketErrorCode?

    var onClose: EventLoopFuture<Void> {
        channel.closeFuture
    }

    init(channel: Channel, type: PeerType) {
        self.channel = channel
        self.type = type
        waitingForClose = false
    }

    @discardableResult
    public func send<S>(_ text: S) -> EventLoopFuture<Void>
        where S: Collection, S.Element == Character
    {
        let string = String(text)
        var buffer = channel.allocator.buffer(capacity: text.count)
        buffer.writeString(string)
        return send(raw: buffer.readableBytesView, opcode: .text, fin: true)
    }

    @discardableResult
    public func send(_ binary: [UInt8]) -> EventLoopFuture<Void> {
        return send(raw: binary, opcode: .binary, fin: true)
    }

    @discardableResult
    public func sendPing() -> EventLoopFuture<Void> {
        log("send ping")
        return send(
            raw: Data(),
            opcode: .ping,
            fin: true
        )
    }

    @discardableResult
    public func send<Data>(raw data: Data,
                           opcode: WebSocketOpcode = .binary,
                           fin: Bool = true) -> EventLoopFuture<Void>
        where Data: DataProtocol
    {
        let promise = eventLoop.makePromise(of: Void.self)
        var buffer = channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        let frame = WebSocketFrame(
            fin: fin,
            opcode: opcode,
            maskKey: makeMaskKey(),
            data: buffer
        )
        channel.writeAndFlush(frame, promise: promise)
        return promise.futureResult
    }

    @discardableResult
    public func close(code: WebSocketErrorCode = .goingAway) -> EventLoopFuture<Void> {
        guard !isClosed else {
            return eventLoop.makeSucceededVoidFuture()
        }
        guard !waitingForClose else {
            return eventLoop.makeSucceededVoidFuture()
        }

        waitingForClose = true
        closeCode = code

        let codeAsInt = UInt16(webSocketErrorCode: code)
        let codeToSend: WebSocketErrorCode
        if codeAsInt == 1005 || codeAsInt == 1006 {
            /// Code 1005 and 1006 are used to report errors to the application, but must never be sent over
            /// the wire (per https://tools.ietf.org/html/rfc6455#section-7.4)
            codeToSend = .normalClosure
        } else {
            codeToSend = code
        }

        var buffer = channel.allocator.buffer(capacity: 2)
        buffer.write(webSocketErrorCode: codeToSend)

        return send(raw: buffer.readableBytesView, opcode: .connectionClose, fin: true)
    }

    func makeMaskKey() -> WebSocketMaskingKey? {
        switch type {
            case .client:
                var bytes: [UInt8] = []
                for _ in 0 ..< 4 {
                    bytes.append(.random(in: .min ..< .max))
                }
                return WebSocketMaskingKey(bytes)
            case .server:
                return nil
        }
    }

    deinit {
        assert(self.isClosed, "WebSocket was not closed before deinit.")
    }
}
