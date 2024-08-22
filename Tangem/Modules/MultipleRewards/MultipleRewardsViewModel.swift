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
    private let yield: YieldInfo
    private let balances: [StakingBalanceInfo]
    private weak var coordinator: MultipleRewardsRoutable?

    private let percentFormatter = PercentFormatter()
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    init(
        tokenItem: TokenItem,
        yield: YieldInfo,
        balances: [StakingBalanceInfo],
        coordinator: MultipleRewardsRoutable
    ) {
        self.tokenItem = tokenItem
        self.yield = yield
        self.balances = balances
        self.coordinator = coordinator

        assert(
            !balances.contains(where: { $0.balanceType != .rewards }),
            "MultipleRewardsViewModel supports only the `rewards balances`"
        )

        setupView()
    }

    func dismiss() {
        coordinator?.dismissMultipleRewards()
    }
}

// MARK: - Private

private extension MultipleRewardsViewModel {
    func setupView() {
        validators = balances.compactMap { balance in
            mapToValidatorViewData(balance: balance)
        }
    }

    func mapToValidatorViewData(balance: StakingBalanceInfo) -> ValidatorViewData? {
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
                    self?.coordinator?.openClaimRewardsFlow(balanceInfo: balance)
                }
            )
        )
    }
}
