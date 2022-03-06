// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import NIO
import NIOWebSocket

final class CloseHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private let channel: WebSocketChannel

    public init(channel: WebSocketChannel) {
        self.channel = channel
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch frame.opcode {
            case .connectionClose:
                log("recive connectionClose")
                if channel.waitingForClose {
                    // peer confirmed close, time to close channel
                    channel.channel.close(mode: .all, promise: nil)
                } else {
                    // peer asking for close, confirm and close output side channel
                    var data = frame.data
                    let maskingKey = frame.maskKey
                    if let maskingKey = maskingKey {
                        data.webSocketUnmask(maskingKey)
                    }
                    channel.close(
                        code: data.readWebSocketErrorCode() ?? .unknown(1005)
                    ).whenComplete { _ in
                        self.channel.channel.close(mode: .all, promise: nil)
                    }
                }
            default:
                context.fireChannelRead(data)
        }
    }
}
