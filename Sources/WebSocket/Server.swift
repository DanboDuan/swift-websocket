// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import NIOCore
import NIOHTTP1
import NIOPosix
import NIOWebSocket

public extension WebSocket {
    static func server(listen address: ListeningAddress,
                       configuration: Configuration = .init(),
                       onConnection: @escaping (HTTPRequestHead, WebSocket) -> Void) {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: configuration.numberOfThreads)
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                let webSocket = NIOWebSocketServerUpgrader(
                    shouldUpgrade: { channel, _ in
                        channel.eventLoop.makeSucceededFuture([:])
                    },
                    upgradePipelineHandler: { channel, req in
                        let wsChannel = WebSocketChannel(channel: channel, type: .server)
                        let ws = WebSocket(channel: wsChannel)
                        return channel.pipeline.addHandlers([
                            PingPongHandler(timeout: configuration.pingInterval, channel: wsChannel),
                            CloseHandler(channel: wsChannel),
                            WebSocketHandler(webSocket: ws),
                        ]).map { _ in
                            onConnection(req, ws)
                        }
                    }
                )
                return channel.pipeline.configureHTTPServerPipeline(
                    withServerUpgrade: (
                        upgraders: [webSocket],
                        completionHandler: { _ in
                            // complete
                        }
                    )
                )
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        let bind: EventLoopFuture<Channel>
        switch address {
            case let .ip(host: host, port: port):
                bind = bootstrap.bind(host: host, port: port)
            case let .unixDomainSocket(path: path):
                bind = bootstrap.bind(unixDomainSocketPath: path, cleanupExistingSocketFile: true)
        }
        if let channel = try? bind.wait() {
            if let port = channel.localAddress?.port {
                log("listening on port \(port)")
            }
            try? channel.closeFuture.wait()
            log("stop listening")
        }
    }
}
