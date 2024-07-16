//
//  StakingBalanceProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingBalanceProvider {
    var balance: StakingBalanceInfo? { get }
    var balancePublisher: AnyPublisher<StakingBalanceInfo?, Never> { get }

    func updateBalance()
}

class CommonStakingBalanceProvider {
    private let item: StakingTokenItem
    private let address: String
    private let provider: StakingAPIProvider

    private var updatingBalancesTask: Task<Void, Never>?
    private let _balance: CurrentValueSubject<StakingBalanceInfo?, Never> = .init(nil)

    init(item: StakingTokenItem, address: String, provider: StakingAPIProvider) {
        self.item = item
        self.address = address
        self.provider = provider
    }
}

// MARK: - StakingBalanceProvider

extension CommonStakingBalanceProvider: StakingBalanceProvider {
    var balance: StakingBalanceInfo? {
        _balance.value
    }

    var balancePublisher: AnyPublisher<StakingBalanceInfo?, Never> {
        _balance.eraseToAnyPublisher()
    }

    func updateBalance() {
        updatingBalancesTask?.cancel()
        updatingBalancesTask = Task { [weak self] in
            guard let self else { return }

            do {
                let balance = try await provider.balance(address: address, network: item.coinId)
                _balance.send(balance)
            } catch {
                AppLog.shared.error(error)
            }
        }
    }
}
