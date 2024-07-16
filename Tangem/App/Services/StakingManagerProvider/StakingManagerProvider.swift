//
//  StakingManagerProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingManagerProvider {
    @Injected(\.stakingRepositoryProxy) private var stakingRepositoryProxy: StakingRepositoryProxy
    private let tokenItem: TokenItem
    private let address: String

    var stakingManager: StakingManager? {
        _stakingManager
    }

    var stateDidUpdatePublisher: AnyPublisher<Void, Never> {
        stateDidUpdate.eraseToAnyPublisher()
    }

    private var _stakingManager: StakingManager?
    private let stateDidUpdate = PassthroughSubject<Void, Never>()
    private var repositoryUpdatedSubscription: AnyCancellable?

    init(tokenItem: TokenItem, address: String) {
        self.tokenItem = tokenItem
        self.address = address

        _stakingManager = makeStakingManager()
        bind()
    }

    func bind() {
        repositoryUpdatedSubscription = stakingRepositoryProxy
            .enabledYieldsPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, _ in
                if provider._stakingManager == nil {
                    provider._stakingManager = provider.makeStakingManager()
                    provider.stateDidUpdate.send(())
                }
            }
    }

    private func makeStakingManager() -> StakingManager? {
        guard StakingFeatureProvider().isAvailable(for: tokenItem) else {
            return nil
        }

        let wallet = StakingWallet(item: tokenItem.stakingTokenItem, address: address)

        guard let yieldInfo = stakingRepositoryProxy.getYield(item: wallet.item) else {
            AppLog.shared.debug("Wallet \(wallet) doesn't support staking")
            return nil
        }

        return StakingDependenciesFactory().makeStakingManager(wallet: wallet, yieldInfo: yieldInfo)
    }
}
