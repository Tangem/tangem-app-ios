//
//  SolanaDummyNetworkRouter.swift
//  BlockchainSdkTests
//
//  Created by Alexander Skibin on 13.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

final class SolanaDummyNetworkRouter: SolanaRouter {
    var endpoint: RPCEndpoint = .init(url: URL(string: "")!, urlWebSocket: URL(string: "")!, network: .testnet)

    private var host: String? { nil }
    private var currentEndpointIndex = 0

    // MARK: - Init

    init() {}

    func request<T: Decodable>(
        method: HTTPMethod = .post,
        bcMethod: String = #function,
        parameters: [Encodable?] = [],
        enableСontinuedRetry: Bool = true,
        onComplete: @escaping (Result<T, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            onComplete(.failure(WorkaroundError.markSuccess))
        }
    }
}

extension SolanaDummyNetworkRouter {
    enum WorkaroundError: Error {
        case markSuccess
    }
}
