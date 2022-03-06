// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


import NIOCore
import NIOHTTP1
import NIOPosix
import NIOWebSocket

extension WebSocketErrorCode {
    init(_ error: NIOWebSocketError) {
        switch error {
            case .invalidFrameLength:
                self = .messageTooLarge
            case .fragmentedControlFrame,
                 .multiByteControlFrameLength:
                self = .protocolError
        }
    }
}

final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    private var webSocket: WebSocket

    public init(webSocket: WebSocket) {
        self.webSocket = webSocket
    }

    public func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        webSocket.handle(incoming: frame)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        let errorCode: WebSocketErrorCode
        if let error = error as? NIOWebSocketError {
            errorCode = WebSocketErrorCode(error)
        } else {
            errorCode = .unexpectedServerError
        }
        _ = webSocket.close(code: errorCode)

        // We always forward the error on to let others see it.
        context.fireErrorCaught(error)
    }

    func channelInactive(context: ChannelHandlerContext) {
        log("channel closed abnormally")
        let closedAbnormally = WebSocketErrorCode.unknown(1006)
        _ = webSocket.close(code: closedAbnormally)

        // We always forward the error on to let others see it.
        context.fireChannelInactive()
    }
}
