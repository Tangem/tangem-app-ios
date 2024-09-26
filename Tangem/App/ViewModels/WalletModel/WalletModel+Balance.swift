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
    struct Balance: Hashable {
        let crypto, fiat: Decimal?
    }

    struct BalanceFormatted: Hashable {
        let crypto, fiat: String
    }

    var allBalance: Balance {
        let cryptoBalance: Decimal? = {
            switch (availableBalance.crypto, stakingManager?.state.balances?.sum()) {
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

    var stakedBalance: Balance {
        let stakingBalance = stakingManagerState.balances?.blocked().sum()
        let fiatBalance: Decimal? = {
            guard let stakingBalance, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(stakingBalance, currencyId: currencyId)
        }()

        return .init(crypto: stakingBalance, fiat: fiatBalance)
    }

    var stakedRewardsBalance: Balance {
        let rewardsToClaim = stakingManagerState.rewardsToClaim
        let fiatBalance: Decimal? = {
            guard let rewardsToClaim, let currencyId = tokenItem.currencyId else {
                return nil
            }

            return converter.convertToFiat(rewardsToClaim, currencyId: currencyId)
        }()

        return .init(crypto: rewardsToClaim, fiat: fiatBalance)
    }

    var allBalanceFormatted: BalanceFormatted {
        formatted(allBalance)
    }

    var stakedBalanceFormatted: BalanceFormatted {
        formatted(stakedBalance)
    }

    var availableBalanceFormatted: BalanceFormatted {
        formatted(availableBalance)
    }

    var stakedRewardsBalanceFormatted: BalanceFormatted {
        formatted(stakedRewardsBalance)
    }

    private func formatted(_ balance: Balance) -> BalanceFormatted {
        let cryptoFormatted = formatter.formatCryptoBalance(balance.crypto, currencyCode: tokenItem.currencySymbol)
        let fiatFormatted = formatter.formatFiatBalance(balance.fiat)

        return .init(crypto: cryptoFormatted, fiat: fiatFormatted)
    }
}

private extension StakingManagerState {
    var balances: [StakingBalance]? {
        guard case .staked(let staked) = self else {
            return nil
        }

        return staked.balances
    }

    var rewardsToClaim: Decimal? {
        guard case .staked(let staked) = self else {
            return nil
        }

        return staked.balances.rewards().sum()
    }
}
