//
//  WalletModel+Balance.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

// MARK: - Balance

extension WalletModel {
    var balanceValue: Decimal? {
        availableBalance.crypto
    }

    var balance: String {
        availableBalanceFormatted.crypto
    }

    var isZeroAmount: Bool {
        wallet.amounts[amountType]?.isZero ?? true
    }

    var fiatBalance: String {
        availableBalanceFormatted.fiat
    }

    var fiatValue: Decimal? {
        availableBalance.fiat
    }

    var totalBalance: Balance {
        let cryptoBalance: Decimal? = {
            switch (availableBalance.crypto, stakedBalance.crypto) {
            case (.none, _): nil
            // What we have to do if we have only blocked balance?
            case (.some(let available), .none): available
            case (.some(let available), .some(let blocked)): available + blocked
            }
        }()

        let fiatBalance: Decimal? = {
            guard let cryptoBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(cryptoBalance, currencyId: currencyId)
        }()

        return .init(crypto: cryptoBalance, fiat: fiatBalance)
    }

    var availableBalance: Balance {
        let cryptoBalance: Decimal? = {
            if state.isNoAccount {
                return 0
            }

            return wallet.amounts[amountType]?.value
        }()

        let fiatBalance: Decimal? = {
            guard let cryptoBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(cryptoBalance, currencyId: currencyId)
        }()

        return .init(crypto: cryptoBalance, fiat: fiatBalance)
    }

    var stakedRewards: Balance {
        let rewardsToClaim = stakingManagerState.balances?.rewards().sum()
        let fiatBalance: Decimal? = {
            guard let rewardsToClaim, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(rewardsToClaim, currencyId: currencyId)
        }()

        return .init(crypto: rewardsToClaim, fiat: fiatBalance)
    }

    var allBalanceFormatted: BalanceFormatted {
        formatted(totalBalance)
    }

    var availableBalanceFormatted: BalanceFormatted {
        formatted(availableBalance)
    }

    var stakedWithPendingBalanceFormatted: BalanceFormatted {
        formatted(stakedWithPendingBalance)
    }

    var stakedBalanceFormatted: BalanceFormatted {
        formatted(stakedBalance)
    }

    var stakedRewardsFormatted: BalanceFormatted {
        formatted(stakedRewards)
    }

    private var stakedBalance: Balance {
        let stakingBalance = stakingManagerState.balances?.blocked().sum()
        let fiatBalance: Decimal? = {
            guard let stakingBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(stakingBalance, currencyId: currencyId)
        }()

        return .init(crypto: stakingBalance, fiat: fiatBalance)
    }

    private var stakedWithPendingBalance: Balance {
        let stakingBalance = stakingManagerState.balances?.stakes().sum()
        let fiatBalance: Decimal? = {
            guard let stakingBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(stakingBalance, currencyId: currencyId)
        }()

        return .init(crypto: stakingBalance, fiat: fiatBalance)
    }

    func formatted(_ balance: Balance) -> BalanceFormatted {
        let cryptoFormatted = formatter.formatCryptoBalance(balance.crypto, currencyCode: tokenItem.currencySymbol)
        let fiatFormatted = formatter.formatFiatBalance(balance.fiat)

        return .init(crypto: cryptoFormatted, fiat: fiatFormatted)
    }
}

extension WalletModel {
    struct Balance: Hashable {
        let crypto, fiat: Decimal?
    }

    struct BalanceFormatted: Hashable {
        let crypto, fiat: String
    }
}
