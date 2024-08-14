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

    @Published var rewardViewData: RewardViewData?
    @Published private(set) var activeValidators: [ValidatorViewData] = []
    @Published private(set) var unstakedValidators: [ValidatorViewData] = []
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?
    @Published var actionButtonLoading: Bool = false
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

    func validatorBalances(yield: YieldInfo, balances: [StakingBalanceInfo]) -> [ValidatorBalanceInfo] {
        balances.compactMap { balance -> ValidatorBalanceInfo? in
            guard let validator = yield.validators.first(where: { $0.address == balance.validatorAddress }) else {
                return nil
            }

            return ValidatorBalanceInfo(
                validator: validator,
                balance: balance.blocked,
                balanceGroupType: balance.balanceGroupType
            )
        }
    }

    func setupView(yield: YieldInfo, balances: [StakingBalanceInfo]) {
        let stakedBalance = balances.sumBlocked()
        let available = (walletModel.balanceValue ?? .zero) - stakedBalance
        let aprs = yield.validators.compactMap(\.apr)
        let validatorBalances = validatorBalances(yield: yield, balances: balances)
        let rewards = balances.sumRewards()

        setupView(
            inputData: StakingDetailsData(
                available: available,
                staked: stakedBalance,
                rewards: rewards,
                rewardType: yield.rewardType,
                rewardRate: yield.rewardRate,
                rewardRateValues: RewardRateValues(aprs: aprs, rewardRate: yield.rewardRate),
                minimumRequirement: yield.enterMinimumRequirement,
                warmupPeriod: yield.warmupPeriod,
                unbondingPeriod: yield.unbondingPeriod,
                rewardClaimingType: yield.rewardClaimingType,
                rewardScheduleType: yield.rewardScheduleType,
                activeValidators: validatorBalances.filter { $0.balanceGroupType != .unbonding },
                unstakedValidators: validatorBalances.filter { $0.balanceGroupType == .unbonding }
            )
        )
    }

    func setupView(inputData: StakingDetailsData) {
        setupHeaderView(inputData: inputData)
        setupDetailsSection(inputData: inputData)
        setupRewardView(inputData: inputData)
        setupValidatorsView(input: inputData)
    }

    func setupHeaderView(inputData: StakingDetailsData) {
        hideStakingInfoBanner = hideStakingInfoBanner && inputData.staked.isZero
    }

    func setupDetailsSection(inputData: StakingDetailsData) {
        var viewModels = [
            DefaultRowViewModel(
                title: Localization.stakingDetailsAnnualPercentageRate,
                detailsType: .text(inputData.rewardRateValues.formatted(formatter: percentFormatter)),
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
                        inputData.available,
                        currencyCode: walletModel.tokenItem.currencySymbol
                    )
                )
            ),
        ]

        if shouldShowMinimumRequirement() {
            let minimumFormatted = balanceFormatter.formatCryptoBalance(
                inputData.minimumRequirement,
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
                    detailsType: .text(inputData.unbondingPeriod.formatted(formatter: daysFormatter)),
                    secondaryAction: { [weak self] in
                        self?.openBottomSheet(
                            title: Localization.stakingDetailsUnbondingPeriod,
                            description: Localization.stakingDetailsUnbondingPeriodInfo
                        )
                    }
                ),
                DefaultRowViewModel(
                    title: Localization.stakingDetailsRewardClaiming,
                    detailsType: .text(inputData.rewardClaimingType.title),
                    secondaryAction: { [weak self] in
                        self?.openBottomSheet(
                            title: Localization.stakingDetailsRewardClaiming,
                            description: Localization.stakingDetailsRewardClaimingInfo
                        )
                    }
                ),
            ]
        )

        if !inputData.warmupPeriod.isZero {
            viewModels.append(DefaultRowViewModel(
                title: Localization.stakingDetailsWarmupPeriod,
                detailsType: .text(inputData.warmupPeriod.formatted(formatter: daysFormatter)),
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
            detailsType: .text(inputData.rewardScheduleType.title),
            secondaryAction: { [weak self] in
                self?.openBottomSheet(
                    title: Localization.stakingDetailsRewardSchedule,
                    description: Localization.stakingDetailsRewardScheduleInfo
                )
            }
        ))

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

            let validatorStakeState: StakingValidatorViewMapper.ValidatorStakeState = {
                switch validatorBalance.balanceGroupType {
                case .unknown: .unknown
                case .warmup: .warmup(period: input.warmupPeriod.formatted(formatter: daysFormatter))
                case .active: .active(apr: validatorBalance.validator.apr)
                case .unbonding: .unbounding(period: input.unbondingPeriod.formatted(formatter: daysFormatter))
                }
            }()

            return StakingValidatorViewMapper().mapToValidatorViewData(
                info: validatorBalance.validator,
                state: validatorStakeState,
                detailsType: .chevron(BalanceInfo(balance: balanceCryptoFormatted, fiatBalance: balanceFiatFormatted))
            )
        }
        activeValidators = input.activeValidators.map(mapToValidatorsData)
        unstakedValidators = input.unstakedValidators.map(mapToValidatorsData)
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
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
        rawValue.capitalizingFirstLetter()
    }
}

private extension RewardScheduleType {
    var title: String {
        switch self {
        case .block:
            // TODO: Update Lokalization when have all requirements
            RewardScheduleType.day.rawValue.capitalizingFirstLetter()
        case .hour, .day, .week, .month, .era, .epoch:
            rawValue.capitalizingFirstLetter()
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
