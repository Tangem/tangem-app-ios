//
//  MultipleRewardsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemStaking

final class MultipleRewardsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let stakingManager: StakingManager
    private weak var coordinator: MultipleRewardsRoutable?

    private let percentFormatter = PercentFormatter()
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    init(
        tokenItem: TokenItem,
        stakingManager: StakingManager,
        coordinator: MultipleRewardsRoutable
    ) {
        self.tokenItem = tokenItem
        self.stakingManager = stakingManager
        self.coordinator = coordinator

        bind()
    }

    func dismiss() {
        coordinator?.dismiss()
    }
}

// MARK: - Private

private extension MultipleRewardsViewModel {
    func bind() {
        guard case .staked(let staked) = stakingManager.state else {
            assertionFailure("StakingManager.state \(stakingManager.state) doesn't support in MultipleRewardsViewModel")
            return
        }

        validators = staked.balances.rewards().compactMap { balance in
            mapToValidatorViewData(yield: staked.yieldInfo, balance: balance)
        }
    }

    func mapToValidatorViewData(yield: YieldInfo, balance: StakingBalanceInfo) -> ValidatorViewData? {
        guard let validator = yield.validators.first(where: { $0.address == balance.validatorAddress }) else {
            return nil
        }

        let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
            balance.amount,
            currencyCode: tokenItem.currencySymbol
        )
        let balanceFiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balance.amount, currencyId: $0)
        }
        let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)

        let subtitleType: ValidatorViewData.SubtitleType? = validator.apr.map {
            .active(apr: percentFormatter.format($0, option: .staking))
        }

        return ValidatorViewData(
            address: validator.address,
            name: validator.name,
            imageURL: validator.iconURL,
            subtitleType: subtitleType,
            detailsType: .balance(
                BalanceInfo(balance: balanceCryptoFormatted, fiatBalance: balanceFiatFormatted),
                action: { [weak self] in
                    self?.coordinator?.openUnstakingFlow(balanceInfo: balance)
                }
            )
        )
    }
}
