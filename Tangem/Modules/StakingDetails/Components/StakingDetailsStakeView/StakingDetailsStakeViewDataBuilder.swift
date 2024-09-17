//
//  StakingDetailsStakeViewDataBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingDetailsStakeViewDataBuilder {
    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var percentFormatter = PercentFormatter()
    private lazy var daysFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }()

    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func mapToStakingDetailsStakeViewData(yield: YieldInfo, balance: StakingBalance, action: @escaping () -> Void) -> StakingDetailsStakeViewData {
        let validator = balance.validatorType.validator
        let inProgress = balance.inProgress

        let title: String = {
            switch balance.balanceType {
            case .rewards: Localization.stakingRewards
            case .locked: inProgress ? Localization.stakingUnlocking : Localization.stakingLocked
            case .warmup, .active: validator?.name ?? Localization.stakingValidator
            case .unbonding: Localization.stakingUnstaking
            case .unstaked: Localization.stakingUnstaked
            }
        }()

        let subtitle: StakingDetailsStakeViewData.SubtitleType? = {
            switch balance.balanceType {
            case .rewards: .none
            case .locked: .locked
            case .unstaked: .withdraw
            case .warmup: .warmup(period: yield.warmupPeriod.formatted(formatter: daysFormatter))
            case .active:
                validator?.apr.map { .active(apr: percentFormatter.format($0, option: .staking)) }
            case .unbonding(let date):
                date.map { .unbonding(until: $0) } ?? .unbondingPeriod(period: yield.unbondingPeriod.formatted(formatter: daysFormatter))
            }
        }()

        let icon: StakingDetailsStakeViewData.IconType = {
            switch balance.balanceType {
            case .rewards, .warmup, .active: .image(url: validator?.iconURL)
            case .locked: .icon(
                    inProgress ? Assets.stakingUnlockingIcon : Assets.stakingLockIcon,
                    color: inProgress ? Colors.Icon.accent : Colors.Icon.informative
                )
            case .unbonding: .icon(Assets.unstakedIcon, color: Colors.Icon.accent)
            case .unstaked: .icon(Assets.unstakedIcon, color: Colors.Icon.informative)
            }
        }()

        let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
            balance.amount,
            currencyCode: tokenItem.currencySymbol
        )
        let balanceFiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balance.amount, currencyId: $0)
        }
        let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)

        let action: (() -> Void)? = {
            switch balance.balanceType {
            case .rewards, .warmup, .unbonding:
                return nil
            case .active, .unstaked, .locked:
                return inProgress ? nil : action
            }
        }()

        return StakingDetailsStakeViewData(
            title: title,
            icon: icon,
            inProgress: inProgress,
            subtitleType: subtitle,
            balance: .init(crypto: balanceCryptoFormatted, fiat: balanceFiatFormatted),
            action: action
        )
    }
}

extension StakingDetailsStakeViewData {
    var priority: Int {
        switch subtitleType {
        case .none: -10
        case .warmup: -2
        case .locked: -1
        case .active: 0
        case .unbonding, .unbondingPeriod: 1
        case .withdraw: 2
        }
    }
}
