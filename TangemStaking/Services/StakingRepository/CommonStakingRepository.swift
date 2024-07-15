//
//  CommonStakingRepository.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonStakingRepository {
    private let provider: StakingAPIProvider
    private let logger: Logger

    private var updatingYieldsTask: Task<Void, Never>?
    private var updatingBalancesTask: Task<Void, Never>?

    private var availableYields: CurrentValueSubject<[YieldInfo]?, Never> = .init(nil)
    private var balances: CurrentValueSubject<[BalanceInfo]?, Never> = .init(nil)

    init(provider: StakingAPIProvider, logger: Logger) {
        self.provider = provider
        self.logger = logger
    }
}

extension CommonStakingRepository: StakingRepository {
    var enabledYieldsPublisher: AnyPublisher<[YieldInfo], Never> {
        availableYields.compactMap { $0 }.eraseToAnyPublisher()
    }

    var balancesPublisher: AnyPublisher<[BalanceInfo], Never> {
        balances.compactMap { $0 }.eraseToAnyPublisher()
    }

    func updateEnabledYields(withReload: Bool) {
        if withReload {
            availableYields.value = nil
        }

        guard availableYields.value == nil else {
            return
        }

        updatingYieldsTask?.cancel()
        updatingYieldsTask = Task { [weak self] in
            do {
                self?.availableYields.value = try await self?.provider.enabledYields()
            } catch {
                self?.logger.error(error)
            }
        }
    }

    func updateBalances(item: StakingTokenItem, address: String) {
        updatingBalancesTask?.cancel()
        updatingBalancesTask = Task { [weak self] in
            guard let self else { return }

            do {
                let balance = try await provider.balance(address: address, network: item.coinId)
                balances.value?.append(balance)
            } catch {
                logger.error(error)
            }
        }
    }

    func getYield(item: StakingTokenItem) -> YieldInfo? {
        availableYields.value?.first(where: { $0.item == item })
    }

    func getBalance(item: StakingTokenItem) -> BalanceInfo? {
        balances.value?.first(where: { $0.item == item })
    }
}
