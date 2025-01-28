//
//  TestnetTokensRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TestnetTokensRepository {
    func loadCoins(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Error> {
        readTestnetList()
            .map { list in
                let mapper = CoinsResponseMapper(supportedBlockchains: requestModel.supportedBlockchains)
                let coins = mapper.mapToCoinModels(list)
                return coins
            }
            .eraseToAnyPublisher()
    }

    // Copy load coins method via async await implementation
    func loadCoins(requestModel: CoinsList.Request) throws -> [CoinModel] {
        let response = try JsonUtils.readBundleFile(with: Constants.testFilename, type: CoinsList.Response.self)
        let mapper = CoinsResponseMapper(supportedBlockchains: requestModel.supportedBlockchains)
        let coins = mapper.mapToCoinModels(response)
        return coins
    }

    private func readTestnetList() -> AnyPublisher<CoinsList.Response, Error> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { _ in
                do {
                    return try JsonUtils.readBundleFile(
                        with: Constants.testFilename,
                        type: CoinsList.Response.self
                    )
                } catch {
                    AppLog.error("Unable to read testnet mock file due to error", error: error)
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension TestnetTokensRepository {
    enum Constants {
        static let testFilename: String = "testnet_tokens"
    }
}
