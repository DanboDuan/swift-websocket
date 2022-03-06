// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import NIO
import NIOHTTP1

final class HTTPInitialRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPClientRequestPart

    let host: String
    let path: String
    let query: String?
    let headers: HTTPHeaders
    let upgradePromise: EventLoopPromise<Void>

    init(address: ServerAddress, headers: HTTPHeaders, upgradePromise: EventLoopPromise<Void>) {
        host = address.host
        path = address.path
        query = address.query
        self.headers = headers
        self.upgradePromise = upgradePromise
    }

    func channelActive(context: ChannelHandlerContext) {
        var headers = self.headers
        headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
        headers.add(name: "Content-Length", value: "\(0)")
        headers.add(name: "Host", value: host)

        var uri = path.hasPrefix("/") ? path : "/" + path
        if let query = query {
            uri += "?\(query)"
        }
        let requestHead = HTTPRequestHead(
            version: HTTPVersion(major: 1, minor: 1),
            method: .GET,
            uri: uri,
            headers: headers
        )
        context.write(wrapOutboundOut(.head(requestHead)), promise: nil)

        let emptyBuffer = context.channel.allocator.buffer(capacity: 0)
        let body = HTTPClientRequestPart.body(.byteBuffer(emptyBuffer))
        context.write(wrapOutboundOut(body), promise: nil)

        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let clientResponse = unwrapInboundIn(data)
        switch clientResponse {
            case let .head(responseHead):
                upgradePromise.fail(WebSocket.Error.invalidResponseStatus(responseHead))
            case .body: break
            case .end:
                context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        upgradePromise.fail(error)
        context.close(promise: nil)
    }
}
