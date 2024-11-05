//
//  URLSessionWebSocketTask.Message+CustomStringConvertible.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension URLSessionWebSocketTask.Message: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .data(let data):
            return "URLSessionWebSocketTask.Message.data: \(data)"
        case .string(let string):
            return "URLSessionWebSocketTask.Message.string: \(string)"
        @unknown default:
            return "URLSessionWebSocketTask.Message.@unknowndefault"
        }
    }
}
