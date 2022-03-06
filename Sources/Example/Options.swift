// Copyright (c) 2022 Bob
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import ArgumentParser
import Foundation

public struct CommandOptions: ParsableArguments {
    @Option(
        name: .customLong("port"),
        help: "connect port"
    )
    public var port = 8000

    @Option(
        name: .customLong("uds"),
        help: "connect path"
    )
    public var path: String?

    public init() {}
}
