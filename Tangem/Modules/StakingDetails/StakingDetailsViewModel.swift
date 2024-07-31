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
    @Published var detailsViewModels: [DefaultRowViewModel] = []
    @Published var averageRewardingViewData: AverageRewardingViewData?
    @Published var rewardViewData: RewardViewData?
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

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

    private let _yieldInfo = CurrentValueSubject<LoadingValue<YieldInfo>, Never>(.loading)
    private let _balanceInfo = CurrentValueSubject<LoadingValue<StakingBalanceInfo>, Never>(.loading)

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

    func userDidTapBanner() {}
    func userDidTapActionButton() {
        coordinator?.openStakingFlow()
    }

    func onAppear() {
        loadValues()
    }
}

private extension StakingDetailsViewModel {
    func loadValues() {
        guard case .availableToStake(let yield) = stakingManager.state else {
            return
        }

        _yieldInfo.send(.loaded(yield))
        // TODO: Dmitry Fedorov
        _balanceInfo.send(.loaded(.init(item: walletModel.tokenItem.stakingTokenItem, blocked: 1.23, rewards: nil, balanceGroupType: .active)))
    }

    func bind() {
        Publishers.CombineLatest(
            _yieldInfo.compactMap { $0.value },
            _balanceInfo.compactMap { $0.value }
        )
        .withWeakCaptureOf(self)
        .receive(on: DispatchQueue.main)
        .sink { viewModel, args in
            viewModel.setupView(yield: args.0, balanceInfo: args.1)
        }
        .store(in: &bag)
    }

    func setupView(yield: YieldInfo, balanceInfo: StakingBalanceInfo) {
        let available = walletModel.balanceValue ?? 0 - balanceInfo.blocked
        let aprs = yield.validators.compactMap(\.apr)
        setupView(
            inputData: StakingDetailsData(
                available: available, // Maybe add skeleton?
                staked: balanceInfo.blocked,
                rewardType: yield.rewardType,
                rewardRate: yield.rewardRate,
                rewardRateValues: RewardRateValues(aprs: aprs, rewardRate: yield.rewardRate),
                minimumRequirement: yield.minimumRequirement,
                warmupPeriod: yield.warmupPeriod,
                unbondingPeriod: yield.unbondingPeriod,
                rewardClaimingType: yield.rewardClaimingType,
                rewardScheduleType: yield.rewardScheduleType
            )
        )
    }

    func setupView(inputData: StakingDetailsData) {
        setupAverageRewardingViewData(inputData: inputData)
        setupDetailsSection(inputData: inputData)
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

        detailsViewModels = [
            DefaultRowViewModel(title: Localization.stakingDetailsAvailable, detailsType: .text(availableFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsOnStake, detailsType: .text(stakedFormatted)),
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
        ]
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
    }
}

extension StakingDetailsViewModel {
    struct StakingDetailsData {
        let available: Decimal
        let staked: Decimal
        let rewardType: RewardType
        let rewardRate: Decimal
        let rewardRateValues: RewardRateValues
        let minimumRequirement: Decimal
        let warmupPeriod: Period
        let unbondingPeriod: Period
        let rewardClaimingType: RewardClaimingType
        let rewardScheduleType: RewardScheduleType
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
