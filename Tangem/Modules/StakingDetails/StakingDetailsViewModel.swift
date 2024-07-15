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

    // MARK: - Dependencies

    private let walletModel: WalletModel
    private let stakingRepository: StakingRepository
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
    private let _balanceInfo = CurrentValueSubject<LoadingValue<TangemStaking.BalanceInfo>, Never>(.loading)

    private var bag: Set<AnyCancellable> = []

    init(
        walletModel: WalletModel,
        stakingRepository: StakingRepository,
        coordinator: StakingDetailsRoutable
    ) {
        self.walletModel = walletModel
        self.stakingRepository = stakingRepository
        self.coordinator = coordinator

        bind()
    }

    func userDidTapBanner() {}
    func userDidTapActionButton() {}

    func onAppear() {
        loadValues()
    }
}

private extension StakingDetailsViewModel {
    func loadValues() {
        guard let yield = stakingRepository.getYield(item: walletModel.stakingTokenItem) else {
            assertionFailure("StakingRepository doesn't contains yield")
            return
        }

        _yieldInfo.send(.loaded(yield))
        _balanceInfo.send(.loaded(.init(item: walletModel.stakingTokenItem, blocked: 1.23)))
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

    func setupView(yield: YieldInfo, balanceInfo: TangemStaking.BalanceInfo) {
        let available = walletModel.balanceValue ?? 0 - balanceInfo.blocked
        setupView(
            inputData: StakingDetailsData(
                available: walletModel.balanceValue ?? 0, // Maybe add skeleton?
                staked: 0, // TBD
                rewardType: yield.rewardType,
                rewardRate: yield.rewardRate,
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
            rewardFormatted: percentFormatter.format(inputData.rewardRate, option: .staking),
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

        let rewardRateFormatted = percentFormatter.format(inputData.rewardRate, option: .staking)

        let unbondingFormatted = inputData.unbondingPeriod.formatted(formatter: daysFormatter)
        let minimumFormatted = balanceFormatter.formatCryptoBalance(
            inputData.minimumRequirement,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let warmupFormatted = inputData.warmupPeriod.formatted(formatter: daysFormatter)

        detailsViewModels = [
            DefaultRowViewModel(title: Localization.stakingDetailsAvailable, detailsType: .text(availableFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsOnStake, detailsType: .text(stakedFormatted)),
            DefaultRowViewModel(title: inputData.rewardType.title, detailsType: .text(rewardRateFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsUnbondingPeriod, detailsType: .text(unbondingFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsMinimumRequirement, detailsType: .text(minimumFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsRewardClaiming, detailsType: .text(inputData.rewardClaimingType.title)),
            DefaultRowViewModel(title: Localization.stakingDetailsWarmupPeriod, detailsType: .text(warmupFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsRewardSchedule, detailsType: .text(inputData.rewardScheduleType.title)),
        ]
    }
}

extension StakingDetailsViewModel {
    struct StakingDetailsData {
        let available: Decimal
        let staked: Decimal
        let rewardType: RewardType
        let rewardRate: Decimal
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
        rawValue.uppercased()
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
