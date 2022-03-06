
// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Logging

func log(_ message: @autoclosure () -> Logger.Message,
         level: LogLevel = .default,
         file: String = #file,
         function: String = #function,
         line: UInt = #line) {
    WebSocketLogger.shared.log(message(), level: level, file: file, function: function, line: line)
}

public final class WebSocketLogger {
    public internal(set) static var shared: WebSocketLogger = .init(logger: Logger(label: "com.websocket.log"))

    private var logger: Logger
    public var enable = false

    internal subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            logger[metadataKey: metadataKey]
        }
        set {
            logger[metadataKey: metadataKey] = newValue
        }
    }

    internal init(logger: @autoclosure () -> Logger) {
        self.logger = logger()
    }

    public func log(_ message: @autoclosure () -> Logger.Message,
                    level: Logger.Level,
                    file: String,
                    function: String,
                    line: UInt) {
        guard enable else { return }
        logger.log(
            level: level,
            message(),
            metadata: nil,
            source: "websocket",
            file: file,
            function: function,
            line: line
        )
    }
}
