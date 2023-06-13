//
//  TestnetTokensRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class TestnetTokensRepository {
    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error> {
        readTestnetList()
            .map { list in
                list.coins.compactMap {
                    CoinModel(with: $0, baseImageURL: list.imageHost)
                        .withFiltered(networkIds: requestModel.networkIds)
                }
            }
            .eraseToAnyPublisher()
    }

    private func readTestnetList() -> AnyPublisher<CoinsResponse, Error> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { _ in
                do {
                    return try JsonUtils.readBundleFile(
                        with: Constants.testFilename,
                        type: CoinsResponse.self
                    )
                } catch {
                    Log.error("Unable to read testnet mock file due to error: \"\(error)\"")
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

private extension CoinModel {
    /// Filter the `tokenItems` for supportedCurves. Used only for testnet coinds from a local file
    func withFiltered(networkIds: String?) -> CoinModel? {
        let networks = networkIds?
            .split(separator: ",")
            .compactMap { String($0) }

        let filteredItems = items.filter { item in
            networks?.contains(item.blockchain.networkId) ?? true
        }

        if filteredItems.isEmpty {
            return nil
        }

        return makeCopy(with: filteredItems)
    }

    private func makeCopy(with items: [TokenItem]) -> CoinModel {
        CoinModel(id: id, name: name, symbol: symbol, imageURL: imageURL, items: items)
    }
}
