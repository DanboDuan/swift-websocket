// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import NIO
import NIOWebSocket

final class PingPongHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    public let timeout: TimeAmount?
    private var scheduledTimeoutTask: Scheduled<Void>?
    private var waitingForPong: Bool
    private let channel: WebSocketChannel
    private var check = false
    public init(timeout: TimeAmount? = nil, channel: WebSocketChannel) {
        self.channel = channel
        self.timeout = timeout
        scheduledTimeoutTask = nil
        waitingForPong = false
    }

    func sendPong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        var frameData = frame.data
        if let maskingKey = frame.maskKey {
            frameData.webSocketUnmask(maskingKey)
        }
        var buffer = context.channel.allocator.buffer(capacity: frameData.readableBytesView.count)
        buffer.writeBytes(frameData.readableBytesView)
        let pong = WebSocketFrame(
            fin: true,
            opcode: .pong,
            maskKey: channel.makeMaskKey(),
            data: buffer
        )
        context.write(wrapOutboundOut(pong), promise: nil)
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch frame.opcode {
            case .ping:
                log("recive ping send pong")
                sendPong(context: context, frame: frame)
            case .pong:
                log("recive pong")
                waitingForPong = false
            default:
                if !check {
                    check = true
                    pingAndScheduleNextTimeoutTask()
                }
                context.fireChannelRead(data)
        }
    }

    private func pingAndScheduleNextTimeoutTask() {
        guard channel.channel.isActive, let timeout = timeout else {
            return
        }

        if waitingForPong {
            channel.close(code: .unknown(1006)).whenComplete { _ in
                // Usually, closing a WebSocket is done by sending the close frame and waiting
                // for the peer to respond with their close frame. We are in a timeout situation,
                // so the other side likely will never send the close frame. We just close the
                // channel ourselves.
                self.channel.channel.close(mode: .all, promise: nil)
            }
        } else {
            channel.sendPing()
            waitingForPong = true
            scheduledTimeoutTask = channel.channel.eventLoop.scheduleTask(
                deadline: .now() + timeout,
                pingAndScheduleNextTimeoutTask
            )
        }
    }

    deinit {
        scheduledTimeoutTask = nil
    }
}
