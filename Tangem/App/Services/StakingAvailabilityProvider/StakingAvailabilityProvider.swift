//
//  StakingAvailabilityProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingAvailabilityProvider: Initializable {
    var availabilityDidUpdatedPublisher: AnyPublisher<Void, Never> { get }

    func manager(tokenItem: TokenItem, address: String) -> StakingManager?
}

extension StakingAvailabilityProvider {
    func isAvailable(tokenItem: TokenItem, address: String) -> Bool {
        manager(tokenItem: tokenItem, address: address) != nil
    }

    func isAvailable(walletModel: WalletModel) -> Bool {
        manager(tokenItem: walletModel.tokenItem, address: walletModel.defaultAddress) != nil
    }

    func manager(walletModel: WalletModel) -> StakingManager? {
        manager(tokenItem: walletModel.tokenItem, address: walletModel.defaultAddress)
    }
}

private struct StakingAvailabilityProviderKey: InjectionKey {
    static var currentValue: StakingAvailabilityProvider = CommonStakingAvailabilityProvider()
}

extension InjectedValues {
    var stakingAvailabilityProvider: StakingAvailabilityProvider {
        get { Self[StakingAvailabilityProviderKey.self] }
        set { Self[StakingAvailabilityProviderKey.self] = newValue }
    }
}
