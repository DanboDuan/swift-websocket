// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import NIO
import NIOHTTP1
import NIOSSL

public enum ListeningAddress {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

public enum ServerAddress {
    case URL(URL: URL)
    case unixDomainSocket(path: String)

    public var scheme: String {
        switch self {
            case let .URL(URL):
                return URL.scheme ?? "ws"
            case .unixDomainSocket:
                return "ws"
        }
    }

    public var host: String {
        switch self {
            case let .URL(URL):
                return URL.host ?? "localhost"
            case .unixDomainSocket:
                return "localhost"
        }
    }

    public var path: String {
        switch self {
            case let .URL(URL):
                return URL.path
            case .unixDomainSocket:
                return "/"
        }
    }

    public var query: String? {
        switch self {
            case let .URL(URL):
                return URL.query
            case .unixDomainSocket:
                return nil
        }
    }

    public var port: Int {
        switch self {
            case let .URL(URL):
                if let port = URL.port {
                    return port
                }
                return scheme == "wss" ? 443 : 80
            case .unixDomainSocket:
                return 0
        }
    }
}

public struct Configuration {
    public var tlsConfiguration: TLSConfiguration?
    public var maxFrameSize: Int
    public var numberOfThreads: Int
    public var pingInterval: TimeAmount?
    public var headers: HTTPHeaders

    public init(tlsConfiguration: TLSConfiguration? = nil,
                maxFrameSize: Int = 1 << 14,
                numberOfThreads: Int = System.coreCount,
                pingInterval: TimeAmount? = nil,
                headers: HTTPHeaders = [:]) {
        self.pingInterval = pingInterval
        self.tlsConfiguration = tlsConfiguration
        self.maxFrameSize = maxFrameSize
        self.numberOfThreads = numberOfThreads
        self.headers = headers
    }
}

enum PeerType {
    case server
    case client
}
