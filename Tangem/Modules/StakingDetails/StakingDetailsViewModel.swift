//
//  StakingDetailsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation
import TangemStaking
import SwiftUI

final class StakingDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { Localization.stakingDetailsTitle(walletModel.name) }
    @Published var hideStakingInfoBanner = true
    @Published var detailsViewModels: [DefaultRowViewModel] = []

    @Published var rewardViewData: RewardViewData?
    @Published private(set) var activeValidators: [ValidatorViewData] = []
    @Published private(set) var unstakedValidators: [ValidatorViewData] = []
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?
    @Published var actionButtonLoading: Bool = false
    @Published var actionButtonType: ActionButtonType?
    @Published var actionSheet: ActionSheetBinder?

    // MARK: - Dependencies

    private let walletModel: WalletModel
    private let stakingManager: StakingManager
    private weak var coordinator: StakingDetailsRoutable?

    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter = PercentFormatter()
    private let daysFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }()

    private var bag: Set<AnyCancellable> = []

    init(
        walletModel: WalletModel,
        stakingManager: StakingManager,
        coordinator: StakingDetailsRoutable
    ) {
        self.walletModel = walletModel
        self.stakingManager = stakingManager
        self.coordinator = coordinator

        bind()
    }

    func refresh() async {
        try? await stakingManager.updateState()
    }

    func userDidTapBanner() {
        coordinator?.openWhatIsStaking()
    }

    func userDidTapActionButton() {
        coordinator?.openStakingFlow()
    }

    func userDidTapHideBanner() {
        AppSettings.shared.hideStakingInfoBanner = true
        hideStakingInfoBanner = true
    }

    func onAppear() {
        loadValues()
    }
}

private extension StakingDetailsViewModel {
    func loadValues() {
        Task {
            try await stakingManager.updateState()
        }
    }

    func bind() {
        stakingManager
            .statePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.setupView(state: state)
            }
            .store(in: &bag)
    }

    func setupView(state: StakingManagerState) {
        switch state {
        case .loading:
            actionButtonLoading = true
        case .notEnabled:
            actionButtonLoading = false
            actionButtonType = .none
        case .temporaryUnavailable(let yieldInfo), .availableToStake(let yieldInfo):
            setupView(yield: yieldInfo, balances: [])

            actionButtonLoading = false
            actionButtonType = .stake
        case .staked(let staked):
            setupView(yield: staked.yieldInfo, balances: staked.balances)

            actionButtonLoading = false
            actionButtonType = staked.canStakeMore ? .stakeMore : .none
        }
    }

    func setupView(yield: YieldInfo, balances: [StakingBalanceInfo]) {
        setupHeaderView(hasBalances: !balances.isEmpty)
        setupDetailsSection(yield: yield, staking: balances.staking())
        setupValidatorsView(yield: yield, staking: balances.staking())
        setupRewardView(yield: yield, balances: balances)
    }

    func setupHeaderView(hasBalances: Bool) {
        hideStakingInfoBanner = hasBalances || AppSettings.shared.hideStakingInfoBanner
    }

    func setupDetailsSection(yield: YieldInfo, staking: [StakingBalanceInfo]) {
        let available = walletModel.availableBalance.crypto
        let aprs = yield.validators.compactMap(\.apr)
        let rewardRateValues = RewardRateValues(aprs: aprs, rewardRate: yield.rewardRate)

        var viewModels = [
            DefaultRowViewModel(
                title: Localization.stakingDetailsAnnualPercentageRate,
                detailsType: .text(rewardRateValues.formatted(formatter: percentFormatter)),
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(
                        title: Localization.stakingDetailsAnnualPercentageRate,
                        description: Localization.stakingDetailsAnnualPercentageRateInfo
                    )
                }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsAvailable,
                detailsType: .text(
                    balanceFormatter.formatCryptoBalance(
                        available,
                        currencyCode: walletModel.tokenItem.currencySymbol
                    )
                )
            ),
        ]

        if shouldShowMinimumRequirement() {
            let minimumFormatted = balanceFormatter.formatCryptoBalance(
                yield.enterMinimumRequirement,
                currencyCode: walletModel.tokenItem.currencySymbol
            )

            viewModels.append(
                DefaultRowViewModel(
                    title: Localization.stakingDetailsMinimumRequirement,
                    detailsType: .text(minimumFormatted)
                )
            )
        }

        viewModels.append(
            contentsOf: [
                DefaultRowViewModel(
                    title: Localization.stakingDetailsUnbondingPeriod,
                    detailsType: .text(yield.unbondingPeriod.formatted(formatter: daysFormatter)),
                    secondaryAction: { [weak self] in
                        self?.openBottomSheet(
                            title: Localization.stakingDetailsUnbondingPeriod,
                            description: Localization.stakingDetailsUnbondingPeriodInfo
                        )
                    }
                ),
                DefaultRowViewModel(
                    title: Localization.stakingDetailsRewardClaiming,
                    detailsType: .text(yield.rewardClaimingType.title),
                    secondaryAction: { [weak self] in
                        self?.openBottomSheet(
                            title: Localization.stakingDetailsRewardClaiming,
                            description: Localization.stakingDetailsRewardClaimingInfo
                        )
                    }
                ),
            ]
        )

        if !yield.warmupPeriod.isZero {
            viewModels.append(DefaultRowViewModel(
                title: Localization.stakingDetailsWarmupPeriod,
                detailsType: .text(yield.warmupPeriod.formatted(formatter: daysFormatter)),
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(
                        title: Localization.stakingDetailsWarmupPeriod,
                        description: Localization.stakingDetailsWarmupPeriodInfo
                    )
                }
            ))
        }

        viewModels.append(DefaultRowViewModel(
            title: Localization.stakingDetailsRewardSchedule,
            detailsType: .text(yield.rewardScheduleType.title),
            secondaryAction: { [weak self] in
                self?.openBottomSheet(
                    title: Localization.stakingDetailsRewardSchedule,
                    description: Localization.stakingDetailsRewardScheduleInfo
                )
            }
        ))

        detailsViewModels = viewModels
    }

    func setupRewardView(yield: YieldInfo, balances: [StakingBalanceInfo]) {
        guard !balances.isEmpty else {
            rewardViewData = nil
            return
        }

        let rewards = balances.rewards()
        switch rewards.sum() {
        case .zero where yield.rewardClaimingType == .auto:
            rewardViewData = nil
        case .zero:
            rewardViewData = RewardViewData(state: .noRewards)
        case let rewardsValue:
            let rewardsCryptoFormatted = balanceFormatter.formatCryptoBalance(
                rewardsValue,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let rewardsFiat = walletModel.tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(rewardsValue, currencyId: $0)
            }
            let rewardsFiatFormatted = balanceFormatter.formatFiatBalance(rewardsFiat)
            rewardViewData = RewardViewData(
                state: .rewards(fiatFormatted: rewardsFiatFormatted, cryptoFormatted: rewardsCryptoFormatted) { [weak self] in
                    if rewards.count == 1, let balance = rewards.first {
                        self?.openUnstakingFlow(balance: balance)
                    } else {
                        self?.coordinator?.openMultipleRewards()
                    }
                }
            )
        }
    }

    func setupValidatorsView(yield: YieldInfo, staking: [StakingBalanceInfo]) {
        activeValidators = staking.filter { $0.balanceType.isActive }.compactMap { balance -> ValidatorViewData? in
            mapToValidatorViewData(yield: yield, balance: balance)
        }

        unstakedValidators = staking.filter { $0.balanceType.isInactive }.compactMap { balance -> ValidatorViewData? in
            mapToValidatorViewData(yield: yield, balance: balance)
        }
    }

    func mapToValidatorViewData(yield: YieldInfo, balance: StakingBalanceInfo) -> ValidatorViewData? {
        guard let validator = yield.validators.first(where: { $0.address == balance.validatorAddress }) else {
            return nil
        }

        let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
            balance.amount,
            currencyCode: walletModel.tokenItem.currencySymbol
        )
        let balanceFiat = walletModel.tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balance.amount, currencyId: $0)
        }
        let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)

        let subtitleType: ValidatorViewData.SubtitleType? = {
            switch balance.balanceType {
            case .rewards: .none
            case .warmup: .warmup(period: yield.warmupPeriod.formatted(formatter: daysFormatter))
            case .active: validator.apr.map { .active(apr: percentFormatter.format($0, option: .staking)) }
            case .unbonding(let date): .unbounding(until: date)
            case .withdraw: .withdraw
            }
        }()

        let action: (() -> Void)? = {
            switch balance.balanceType {
            case .rewards, .warmup, .unbonding:
                return nil
            case .active, .withdraw:
                return { [weak self] in
                    self?.openUnstakingFlow(balance: balance)
                }
            }
        }()

        return ValidatorViewData(
            address: validator.address,
            name: validator.name,
            imageURL: validator.iconURL,
            subtitleType: subtitleType,
            detailsType: .balance(
                BalanceInfo(balance: balanceCryptoFormatted, fiatBalance: balanceFiatFormatted),
                action: action
            )
        )
    }

    func remainDaysFormat(date: Date) -> String {
        guard let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day else {
            return date.formatted()
        }

        return daysFormatter.string(from: DateComponents(day: days)) ?? days.formatted()
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
    }

    func openUnstakingFlow(balance: StakingBalanceInfo) {
        switch PendingActionMapper(balanceInfo: balance).getAction() {
        case .none:
            break
        case .single(let action):
            coordinator?.openUnstakingFlow(action: action)
        case .multiple(let actions):
            var buttons: [Alert.Button] = actions.map { action in
                .default(Text(action.type.title)) { [weak self] in
                    self?.coordinator?.openUnstakingFlow(action: action)
                }
            }

            buttons.append(.cancel())
            actionSheet = .init(sheet: .init(title: Text(Localization.commonSelectAction), buttons: buttons))
        }
    }

    func shouldShowMinimumRequirement() -> Bool {
        switch walletModel.tokenItem.blockchain {
        case .polkadot, .binance: true
        default: false
        }
    }
}

extension StakingDetailsViewModel {
    enum ActionButtonType: Hashable {
        case stake
        case stakeMore

        var title: String {
            switch self {
            case .stake: Localization.commonStake
            case .stakeMore: Localization.stakingStakeMore
            }
        }
    }
}

extension Period {
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        }
    }
}

private extension RewardClaimingType {
    var title: String {
        switch self {
        case .auto: Localization.stakingRewardClaimingAuto
        case .manual: Localization.stakingRewardClaimingManual
        }
    }
}

private extension RewardScheduleType {
    var title: String {
        switch self {
        case .hour: Localization.stakingRewardScheduleHour
        case .day: Localization.stakingRewardScheduleEachDay
        case .week: Localization.stakingRewardScheduleWeek
        case .month: Localization.stakingRewardScheduleMonth
        }
    }
}

private extension RewardRateValues {
    func formatted(formatter: PercentFormatter) -> String {
        switch self {
        case .single(let value):
            formatter.format(value, option: .staking)
        case .interval(let min, let max):
            formatter.formatInterval(min: min, max: max, option: .staking)
        }
    }
}

private extension BalanceType {
    var isActive: Bool {
        switch self {
        case .warmup, .active:
            return true
        case .unbonding, .withdraw, .rewards:
            return false
        }
    }

    var isInactive: Bool {
        switch self {
        case .unbonding, .withdraw:
            return true
        case .warmup, .active, .rewards:
            return false
        }
    }
}

extension StakingAction.ActionType {
    var title: String {
        switch self {
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .pending(.withdraw): Localization.stakingWithdraw
        case .pending(.claimRewards): Localization.commonClaimRewards
        case .pending(.restakeRewards): Localization.stakingRestakeRewards
        }
    }
}
