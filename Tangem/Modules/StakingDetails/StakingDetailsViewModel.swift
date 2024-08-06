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

final class StakingDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { Localization.stakingDetailsTitle(walletModel.name) }
    @Published var hideStakingInfoBanner = AppSettings.shared.hideStakingInfoBanner
    @Published var detailsViewModels: [DefaultRowViewModel] = []
    @Published var averageRewardingViewData: AverageRewardingViewData?
    @Published var rewardViewData: RewardViewData?
    @Published private(set) var activeValidators: [ValidatorViewData] = []
    @Published private(set) var unstakedValidators: [ValidatorViewData] = []
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?
    @Published var actionButtonType: ActionButtonType?

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

    func userDidTapBanner() {
        coordinator?.openWhatIsStaking()
    }

    func userDidTapActionButton() {
        coordinator?.openStakingFlow()
    }

    func userDidTapValidator(validator: String) {
        coordinator?.openUnstakingFlow(validator: validator)
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
        case .loading, .notEnabled:
            break
        case .availableToStake(let yieldInfo):
            setupView(yield: yieldInfo, balancesInfo: nil)
            actionButtonType = .stake
        case .staked(let staked):
            setupView(yield: staked.yieldInfo, balancesInfo: staked.balances)
            actionButtonType = staked.canStakeMore ? .stakeMore : .none
        }
    }

    func setupView(yield: YieldInfo, balancesInfo: [StakingBalanceInfo]?) {
        let stakedBalance = balancesInfo.flatMap { $0.sumBlocked() } ?? .zero
        let available = walletModel.balanceValue ?? .zero - stakedBalance
        let aprs = yield.validators.compactMap(\.apr)
        var validatorBalances: [ValidatorBalanceInfo] = []
        if let balancesInfo {
            validatorBalances = yield.validators.compactMap { validatorInfo -> ValidatorBalanceInfo? in
                guard let balanceInfo = balancesInfo.filter({ $0.validatorAddress == validatorInfo.address }).first else {
                    return nil
                }
                return ValidatorBalanceInfo(
                    validator: validatorInfo,
                    balance: balanceInfo.blocked,
                    balanceGroupType: balanceInfo.balanceGroupType
                )
            }
        }
        let rewards = balancesInfo?.sumRewards()
        setupView(
            inputData: StakingDetailsData(
                available: available, // Maybe add skeleton?
                staked: stakedBalance,
                rewards: rewards,
                rewardType: yield.rewardType,
                rewardRate: yield.rewardRate,
                rewardRateValues: RewardRateValues(aprs: aprs, rewardRate: yield.rewardRate),
                minimumRequirement: yield.minimumRequirement,
                warmupPeriod: yield.warmupPeriod,
                unbondingPeriod: yield.unbondingPeriod,
                rewardClaimingType: yield.rewardClaimingType,
                rewardScheduleType: yield.rewardScheduleType,
                activeValidators: validatorBalances.filter { $0.balanceGroupType == .active },
                unstakedValidators: validatorBalances.filter { $0.balanceGroupType == .unstaked }
            )
        )
    }

    func setupView(inputData: StakingDetailsData) {
        setupHeaderView(inputData: inputData)
        setupAverageRewardingViewData(inputData: inputData)
        setupDetailsSection(inputData: inputData)
        setupRewardView(inputData: inputData)
        setupValidatorsView(input: inputData)
        setupButtonTitle(inputData: inputData)
    }

    func setupHeaderView(inputData: StakingDetailsData) {
        hideStakingInfoBanner = hideStakingInfoBanner && inputData.staked.isZero
    }

    func setupAverageRewardingViewData(inputData: StakingDetailsData) {
        let days = 30
        let periodProfitFormatted = daysFormatter.string(from: DateComponents(day: days)) ?? days.formatted()

        let profitFormatted = walletModel.balanceValue.map { balanceValue in
            let profit = StakingCalculator().earnValue(
                invest: balanceValue,
                apr: inputData.rewardRate,
                period: .days(days)
            )
            return balanceFormatter.formatFiatBalance(profit)
        }

        averageRewardingViewData = .init(
            rewardType: inputData.rewardType.title,
            rewardFormatted: inputData.rewardRateValues.formatted(formatter: percentFormatter),
            periodProfitFormatted: periodProfitFormatted,
            profitFormatted: profitFormatted.map { .loaded(text: $0) } ?? .noData
        )
    }

    func setupDetailsSection(inputData: StakingDetailsData) {
        let availableFormatted = balanceFormatter.formatCryptoBalance(
            inputData.available,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let stakedFormatted = balanceFormatter.formatCryptoBalance(
            inputData.staked,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let rewardRateFormatted = inputData.rewardRateValues.formatted(formatter: percentFormatter)

        let unbondingFormatted = inputData.unbondingPeriod.formatted(formatter: daysFormatter)
        let minimumFormatted = balanceFormatter.formatCryptoBalance(
            inputData.minimumRequirement,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let warmupFormatted = inputData.warmupPeriod.formatted(formatter: daysFormatter)

        var rewardSecondaryAction: (() -> Void)?
        if let rewardTypeDescrption = inputData.rewardType.description {
            rewardSecondaryAction = { [weak self] in
                self?.openBottomSheet(title: inputData.rewardType.title, description: rewardTypeDescrption)
            }
        }

        var viewModels = [
            DefaultRowViewModel(title: Localization.stakingDetailsAvailable, detailsType: .text(availableFormatted)),
        ]

        if !inputData.staked.isZero {
            viewModels.append(
                DefaultRowViewModel(title: Localization.stakingDetailsOnStake, detailsType: .text(stakedFormatted))
            )
        }

        viewModels.append(contentsOf: [
            DefaultRowViewModel(
                title: inputData.rewardType.title,
                detailsType: .text(
                    rewardRateFormatted
                ),
                secondaryAction: rewardSecondaryAction
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsUnbondingPeriod,
                detailsType: .text(unbondingFormatted),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsUnbondingPeriod,
                    description: Localization.stakingDetailsUnbondingPeriodInfo
                ) }
            ),
            DefaultRowViewModel(title: Localization.stakingDetailsMinimumRequirement, detailsType: .text(minimumFormatted)),
            DefaultRowViewModel(
                title: Localization.stakingDetailsRewardClaiming,
                detailsType: .text(inputData.rewardClaimingType.title),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsRewardClaiming,
                    description: Localization.stakingDetailsRewardClaimingInfo
                ) }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsWarmupPeriod,
                detailsType: .text(warmupFormatted),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsWarmupPeriod,
                    description: Localization.stakingDetailsWarmupPeriodInfo
                ) }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsRewardSchedule,
                detailsType: .text(inputData.rewardScheduleType.title),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsRewardSchedule,
                    description: Localization.stakingDetailsRewardScheduleInfo
                ) }
            ),
        ])

        detailsViewModels = viewModels
    }

    func setupRewardView(inputData: StakingDetailsData) {
        guard !inputData.staked.isZero else {
            rewardViewData = nil
            return
        }
        let state: RewardViewData.State
        if let rewards = inputData.rewards {
            let rewardsCryptoFormatted = balanceFormatter.formatCryptoBalance(
                rewards,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let rewardsFiat = walletModel.tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(rewards, currencyId: $0)
            }
            let rewardsFiatFormatted = balanceFormatter.formatFiatBalance(rewardsFiat)
            state = .rewards(fiatFormatted: rewardsFiatFormatted, cryptoFormatted: rewardsCryptoFormatted)
        } else {
            state = .noRewards
        }
        rewardViewData = RewardViewData(state: state)
    }

    func setupValidatorsView(input: StakingDetailsData) {
        let mapToValidatorsData: (ValidatorBalanceInfo) -> ValidatorViewData = { [self] validatorBalance in
            let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
                validatorBalance.balance,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let balanceFiat = walletModel.tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(validatorBalance.balance, currencyId: $0)
            }
            let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)

            let validatorStakeState: StakingValidatorViewMapper.ValidatorStakeState =
                switch validatorBalance.balanceGroupType {
            case .active, .unknown: .active(apr: validatorBalance.validator.apr)
            case .unstaked: .unstaked(
                    unboundingPeriod: input.unbondingPeriod.formatted(formatter: DateComponentsFormatter())
                )
            }

            return StakingValidatorViewMapper().mapToValidatorViewData(
                info: validatorBalance.validator,
                state: validatorStakeState,
                detailsType: .chevron(BalanceInfo(balance: balanceCryptoFormatted, fiatBalance: balanceFiatFormatted))
            )
        }
        activeValidators = input.activeValidators.map(mapToValidatorsData)
        unstakedValidators = input.unstakedValidators.map(mapToValidatorsData)
    }

    func setupButtonTitle(inputData: StakingDetailsData) {
        actionButtonType = inputData.staked.isZero ? .stake : .stakeMore
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
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

    struct StakingDetailsData {
        let available: Decimal
        let staked: Decimal
        let rewards: Decimal?
        let rewardType: RewardType
        let rewardRate: Decimal
        let rewardRateValues: RewardRateValues
        let minimumRequirement: Decimal
        let warmupPeriod: Period
        let unbondingPeriod: Period
        let rewardClaimingType: RewardClaimingType
        let rewardScheduleType: RewardScheduleType
        let activeValidators: [ValidatorBalanceInfo]
        let unstakedValidators: [ValidatorBalanceInfo]
    }
}

private extension Period {
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        }
    }
}

private extension DateComponentsFormatter {
    func formatted(days: Int) -> String {
        return string(from: DateComponents(day: days)) ?? days.formatted()
    }
}

private extension RewardType {
    var title: String {
        switch self {
        case .apr:
            Localization.stakingDetailsApr
        case .apy:
            Localization.stakingDetailsApy
        case .variable:
            rawValue.uppercased()
        }
    }

    var description: String? {
        guard case .apy = self else {
            return nil
        }
        return Localization.stakingDetailsApyInfo
    }
}

private extension RewardClaimingType {
    var title: String {
        rawValue.capitalizingFirstLetter()
    }
}

private extension RewardScheduleType {
    var title: String {
        rawValue.capitalizingFirstLetter()
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
