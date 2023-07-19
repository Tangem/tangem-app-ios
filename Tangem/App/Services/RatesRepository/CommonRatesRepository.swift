//
//  CommonFiatRatesRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonRatesRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var _rates: CurrentValueSubject<Rates, Never> = .init([:])
}

extension CommonRatesRepository: RatesRepository {
    var rates: Rates {
        _rates.value
    }

    var ratesPublisher: AnyPublisher<Rates, Never> {
        _rates.eraseToAnyPublisher()
    }

    func update() -> AnyPublisher<Rates, Never> {
        let coinIds = [String](rates.keys)
        return loadRates(coinIds: coinIds)
    }

    func loadRates(coinIds: [String]) -> AnyPublisher<Rates, Never> {
        tangemApiService
            .loadRates(for: coinIds)
            .replaceError(with: [:])
            .handleEvents(receiveOutput: { [weak self] loadedRates in
                guard let self else { return }

                var current = _rates.value

                loadedRates.forEach {
                    current[$0.key] = $0.value
                }

                _rates.send(current)
            })
            .eraseToAnyPublisher()
    }

    func rate(for coinId: String) async throws -> Decimal {
        var rate = rates[coinId]

        if rate == nil {
            let loadedRates = await loadRates(coinIds: [coinId])
            rate = loadedRates[coinId]
        }

        guard let rate else {
            throw CommonError.noData
        }

        return rate
    }
}
