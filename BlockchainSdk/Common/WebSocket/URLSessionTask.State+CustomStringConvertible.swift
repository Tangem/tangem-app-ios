//
//  URLSessionTask.State+CustomStringConvertible.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension URLSessionTask.State: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .running:
            return "URLSessionTask.State.running"
        case .suspended:
            return "URLSessionTask.State.suspended"
        case .canceling:
            return "URLSessionTask.State.canceling"
        case .completed:
            return "URLSessionTask.State.completed"
        @unknown default:
            return "URLSessionTask.State.@unknowndefault"
        }
    }
}
