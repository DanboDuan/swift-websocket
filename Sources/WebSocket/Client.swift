// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import NIOCore
import NIOHTTP1
import NIOPosix
import NIOSSL
import NIOWebSocket

public extension WebSocket {
    static func client(connect address: ServerAddress,
                       configuration: Configuration = .init())
        -> WebSocket? {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: configuration.numberOfThreads)

        let promise: EventLoopPromise<WebSocket> = eventLoopGroup.next().makePromise()
        let upgradePromise = eventLoopGroup.next().makePromise(of: Void.self)

        let scheme = address.scheme
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let httpHandler = HTTPInitialRequestHandler(
                    address: address,
                    headers: configuration.headers,
                    upgradePromise: upgradePromise
                )
                /// key
                var key: [UInt8] = []
                for _ in 0 ..< 16 {
                    key.append(.random(in: .min ..< .max))
                }
                let websocketUpgrader = NIOWebSocketClientUpgrader(
                    requestKey: Data(key).base64EncodedString(),
                    maxFrameSize: configuration.maxFrameSize,
                    automaticErrorHandling: true,
                    upgradePipelineHandler: { channel, _ in
                        let wsChannel = WebSocketChannel(channel: channel, type: .client)
                        let webSocket = WebSocket(channel: wsChannel)
                        return channel.pipeline.addHandlers([
                            PingPongHandler(timeout: configuration.pingInterval, channel: wsChannel),
                            CloseHandler(channel: wsChannel),
                            WebSocketHandler(webSocket: webSocket),
                        ]).map { _ in
                            promise.succeed(webSocket)
                        }
                    }
                )

                let config: NIOHTTPClientUpgradeConfiguration = (
                    upgraders: [websocketUpgrader],
                    completionHandler: { _ in
                        upgradePromise.succeed(())
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )

                if scheme == "wss" {
                    do {
                        let context = try NIOSSLContext(
                            configuration: configuration.tlsConfiguration ?? .makeClientConfiguration()
                        )
                        let tlsHandler = try NIOSSLClientHandler(context: context, serverHostname: address.host)
                        return channel.pipeline.addHandler(tlsHandler).flatMap {
                            channel.pipeline.addHTTPClientHandlers(leftOverBytesStrategy: .forwardBytes, withClientUpgrade: config)
                        }.flatMap {
                            channel.pipeline.addHandler(httpHandler)
                        }
                    } catch {
                        return channel.pipeline.close(mode: .all)
                    }
                } else {
                    return channel.pipeline.addHTTPClientHandlers(
                        leftOverBytesStrategy: .forwardBytes,
                        withClientUpgrade: config
                    ).flatMap {
                        channel.pipeline.addHandler(httpHandler)
                    }
                }
            }

        let connect: EventLoopFuture<Channel>
        switch address {
            case .URL(URL: _):
                connect = bootstrap.connect(host: address.host, port: address.port)
            case let .unixDomainSocket(path: path):
                connect = bootstrap.connect(unixDomainSocketPath: path)
        }
        connect.cascadeFailure(to: upgradePromise)
        connect.cascadeFailure(to: promise)
        let websocket = try? connect.flatMap { _ in
            promise.futureResult
        }.wait()

        return websocket
    }
}
