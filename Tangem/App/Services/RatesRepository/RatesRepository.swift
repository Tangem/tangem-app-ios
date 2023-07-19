//
//  RatesRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 05.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

typealias Rates = [String: Decimal]

protocol RatesRepository: AnyObject {
    var rates: Rates { get }
    var ratesPublisher: AnyPublisher<Rates, Never> { get }

    // TBD: Do we need update?
    func update() -> AnyPublisher<Rates, Never>
    func loadRates(coinIds: [String]) -> AnyPublisher<Rates, Never>
    func rate(for coinId: String) async throws -> Decimal
}

extension RatesRepository {
    func update() async -> Rates {
        return await update().async()
    }

    func loadRates(coinIds: [String]) async -> Rates {
        return await loadRates(coinIds: coinIds).async()
    }
}

private struct RatesProviderKey: InjectionKey {
    static var currentValue: RatesRepository = CommonRatesRepository()
}

extension InjectedValues {
    var ratesRepository: RatesRepository {
        get { Self[RatesProviderKey.self] }
        set { Self[RatesProviderKey.self] = newValue }
    }
}
