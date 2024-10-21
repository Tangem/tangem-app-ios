//
//  URLSessionWebSocketTask.CloseCode+CustomStringConvertible.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension URLSessionWebSocketTask.CloseCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid:
            return "URLSessionWebSocketTask.CloseCode.invalid"
        case .normalClosure:
            return "URLSessionWebSocketTask.CloseCode.normalClosure"
        case .goingAway:
            return "URLSessionWebSocketTask.CloseCode.goingAway"
        case .protocolError:
            return "URLSessionWebSocketTask.CloseCode.protocolError"
        case .unsupportedData:
            return "URLSessionWebSocketTask.CloseCode.unsupportedData"
        case .noStatusReceived:
            return "URLSessionWebSocketTask.CloseCode.noStatusReceived"
        case .abnormalClosure:
            return "URLSessionWebSocketTask.CloseCode.abnormalClosure"
        case .invalidFramePayloadData:
            return "URLSessionWebSocketTask.CloseCode.invalidFramePayloadData"
        case .policyViolation:
            return "URLSessionWebSocketTask.CloseCode.policyViolation"
        case .messageTooBig:
            return "URLSessionWebSocketTask.CloseCode.messageTooBig"
        case .mandatoryExtensionMissing:
            return "URLSessionWebSocketTask.CloseCode.mandatoryExtensionMissing"
        case .internalServerError:
            return "URLSessionWebSocketTask.CloseCode.internalServerError"
        case .tlsHandshakeFailure:
            return "URLSessionWebSocketTask.CloseCode.tlsHandshakeFailure"
        @unknown default:
            return "URLSessionWebSocketTask.CloseCode.@unknowndefault"
        }
    }
}
