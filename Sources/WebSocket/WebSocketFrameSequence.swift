// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT


import NIO
import NIOWebSocket

struct WebSocketFrameSequence {
    var binaryBuffer: ByteBuffer
    var textBuffer: String
    var type: WebSocketOpcode

    init(type: WebSocketOpcode) {
        binaryBuffer = ByteBufferAllocator().buffer(capacity: 0)
        textBuffer = .init()
        self.type = type
    }

    mutating func append(_ frame: WebSocketFrame) {
        var data = frame.unmaskedData
        switch type {
            case .binary:
                binaryBuffer.writeBuffer(&data)
            case .text:
                if let string = data.readString(length: data.readableBytes) {
                    textBuffer += string
                }
            default: break
        }
    }
}
