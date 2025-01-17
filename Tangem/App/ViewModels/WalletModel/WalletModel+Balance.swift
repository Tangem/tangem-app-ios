//
//  WalletModel+Balance.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

// MARK: - BalanceState

extension WalletModel {
    /// Simple flag to check exactly BSDK balance
    var balanceState: BalanceState? {
        switch wallet.amounts[amountType]?.value {
        case .none: .none
        case .zero: .zero
        case .some: .positive
        }
    }

    enum BalanceState {
        case zero
        case positive
    }
}

// MARK: - Providers

extension WalletModel {
    var availableBalanceProvider: TokenBalanceProvider {
        AvailableBalanceProvider(walletModel: self)
    }

    var stakingBalanceProvider: TokenBalanceProvider {
        StakingBalanceProvider(walletModel: self)
    }

    var combineBalanceProvider: TokenBalanceProvider {
        CombineBalanceProvider(
            walletModel: self,
            availableBalanceProvider: availableBalanceProvider,
            stakingBalanceProvider: stakingBalanceProvider
        )
    }

    var availableFiatBalanceProvider: TokenBalanceProvider {
        FiatBalanceProvider(walletModel: self, cryptoBalanceProvider: availableBalanceProvider)
    }

    var stakingFiatBalanceProvider: TokenBalanceProvider {
        FiatBalanceProvider(walletModel: self, cryptoBalanceProvider: stakingBalanceProvider)
    }

    var combineFiatBalanceProvider: TokenBalanceProvider {
        FiatBalanceProvider(walletModel: self, cryptoBalanceProvider: combineBalanceProvider)
    }
}

// MARK: - Rate

extension WalletModel {
    enum Rate: Hashable {
        case custom
        case loading(cached: TokenQuote?)
        case failure(cached: TokenQuote?)
        case loaded(TokenQuote)

        var isLoading: Bool {
            switch self {
            case .loading: true
            case .custom, .failure, .loaded: false
            }
        }

        var cached: TokenQuote? {
            switch self {
            case .custom, .loaded: nil
            case .loading(let cached), .failure(let cached): cached
            }
        }

        var quote: TokenQuote? {
            switch self {
            case .custom: nil
            case .loading(let cached), .failure(let cached): cached
            case .loaded(let quote): quote
            }
        }
    }
}
