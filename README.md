# Websocket

light Websocket written in Swift base on Swift NIO

# Feauture

- ✅ base on Swift NIO for high-performance
- ✅ user-friendly API
- ✅ auto ping

# TODO

- [ ] add unit test

## Usage



### create server or client

- Server 

```swift
        let address: ListeningAddress = .ip(host: "localhost", port: 8000)
        WebSocket.server(listen: address, configuration: Configuration(pingInterval: .seconds(10))) { _, websocket in
            print("new client connect")
            websocket.onText { _, text in
                print("recive text from client:", text)
                websocket.send(text)
            }
            websocket.onBinary { _, binary in
                var data = binary
                if let value = data.readBytes(length: data.readableBytes) {
                    print("recive binary from client:", String(bytes: value, encoding: .utf8) ?? "")
                    websocket.send(value)
                }
            }
            _ = websocket.onClose.always { _ in
                print("client close connection")
            }
        }

```

- client

```swift
        let address: ServerAddress = .URL(URL: URL(string: "ws://127.0.0.1:\(8000)")!)
        if let websocket = WebSocket.client(connect: address, configuration: Configuration(pingInterval: .seconds(10))) {
            websocket.onText { _, text in
                print("recive text from server:", text)
            }
            websocket.onBinary { _, binary in
                var data = binary
                if let value = data.readBytes(length: data.readableBytes) {
                    print("recive binary from client:", String(bytes: value, encoding: .utf8) ?? "")
                }
            }

            websocket.send("hello test")
            websocket.send([UInt8]("hello test".utf8))
            try? websocket.onClose.wait()
        }
```


## Installation

```
dependencies: [
    .package(url: "https://github.com/DanboDuan/swift-websocket.git", .upToNextMajor(from: "1.0.0"))
]
```
## Credits

- [apple/swift-nio-examples](https://github.com/apple/swift-nio-examples) 
- [apple/swift-nio](https://github.com/apple/swift-nio)  
- [vapor/websocket-kit](https://github.com/vapor/websocket-kit)  


## License

[MIT](https://github.com/DanboDuan/swift-websocket/blob/master/LICENSE)

