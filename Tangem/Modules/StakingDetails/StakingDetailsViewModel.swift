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
    @Injected(\.stakingPendingTransactionsRepository) private var stakingPendingTransactionsRepository: StakingPendingTransactionsRepository

    // MARK: - ViewState

    var title: String { Localization.stakingDetailsTitle(walletModel.name) }

    @Published var hideStakingInfoBanner = true
    @Published var detailsViewModels: [DefaultRowViewModel] = []

    @Published var rewardViewData: RewardViewData?
    @Published var stakes: [StakingDetailsStakeViewData] = []
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?
    @Published var actionButtonLoading: Bool = false
    @Published var actionButtonDisabled: Bool = false
    @Published var actionButtonType: ActionButtonType?
    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    lazy var legalText = makeLegalText()

    // MARK: - Dependencies

    private let walletModel: WalletModel
    private let stakingManager: StakingManager
    private lazy var stakingDetailsStakesProvider = StakingDetailsStakeViewDataBuilder(tokenItem: walletModel.tokenItem)
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

    func onAppear() {
        loadValues()
        let balances = stakingManager.state.balances.flatMap { String($0.count) } ?? String(0)
        Analytics.log(
            event: .stakingInfoScreenOpened,
            params: [.validatorsCount: balances]
        )
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

        walletModel
            .walletDidChangePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.setupMainActionButton(state: state)
            }
            .store(in: &bag)

        stakingPendingTransactionsRepository
            .recordsPublisher
            .combineLatest(stakingManager.statePublisher)
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.setupView(state: state.1)
            }
            .store(in: &bag)
    }

    func setupMainActionButton(state: WalletModel.State) {
        switch state {
        case .created, .loading:
            break
        case .idle, .failed, .noAccount, .noDerivation:
            let hasBalance = (walletModel.availableBalance.crypto ?? 0) > 0
            actionButtonDisabled = !hasBalance
        }
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
            stakingPendingTransactionsRepository.checkIfConfirmed(balances: staked.balances)
            setupView(yield: staked.yieldInfo, balances: staked.balances)

            actionButtonLoading = false
            actionButtonType = staked.canStakeMore ? .stakeMore : .none
        }
    }

    func setupView(yield: YieldInfo, balances: [StakingBalanceInfo]) {
        setupHeaderView(hasBalances: !balances.isEmpty)
        setupDetailsSection(yield: yield, staking: balances.staking())
        setupStakes(yield: yield, staking: balances.staking())
        setupRewardView(yield: yield, balances: balances)
    }

    func setupHeaderView(hasBalances: Bool) {
        hideStakingInfoBanner = hasBalances
    }

    func setupDetailsSection(yield: YieldInfo, staking: [StakingBalanceInfo]) {
        var viewModels = [
            DefaultRowViewModel(
                title: Localization.stakingDetailsAnnualPercentageRate,
                detailsType: .text(yield.rewardRateValues.formatted(formatter: percentFormatter)),
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(
                        title: Localization.stakingDetailsAnnualPercentageRate,
                        description: Localization.stakingDetailsAnnualPercentageRateInfo
                    )
                }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsAvailable,
                detailsType: .text(walletModel.availableBalanceFormatted.crypto, sensitive: true)
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
            rewardViewData = RewardViewData(state: .automaticRewards)
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

                        let validator = yield.validators.first(
                            where: { $0.address == balance.validatorAddress }
                        )
                        Analytics.log(event: .stakingButtonRewards, params: [.validator: validator?.name ?? ""])
                    } else {
                        self?.coordinator?.openMultipleRewards()
                    }
                }
            )
        }
    }

    func setupStakes(yield: YieldInfo, staking: [StakingBalanceInfo]) {
        let cachedStakes = stakingPendingTransactionsRepository.records.filter { $0.type == .stake }.compactMap { record in
            stakingDetailsStakesProvider.mapToStakingDetailsStakeViewData(yield: yield, record: record)
        }

        let staking = staking.map { balance in
            stakingDetailsStakesProvider.mapToStakingDetailsStakeViewData(yield: yield, balance: balance) { [weak self] in
                Analytics.log(
                    event: .stakingButtonValidator,
                    params: [.source: Analytics.ParameterValue.stakeSourceStakeInfo.rawValue]
                )
                self?.openUnstakingFlow(balance: balance)
            }
        }

        stakes = (cachedStakes + staking).sorted(by: { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }

            return lhs.balance.crypto > rhs.balance.crypto
        })
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
    }

    func openUnstakingFlow(balance: StakingBalanceInfo) {
        do {
            let action = try PendingActionMapper(balanceInfo: balance).getAction()
            switch action {
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
        } catch {
            alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
        }
    }

    func shouldShowMinimumRequirement() -> Bool {
        switch walletModel.tokenItem.blockchain {
        case .polkadot, .binance: true
        default: false
        }
    }

    func makeLegalText() -> AttributedString {
        let tos = Localization.commonTermsOfUse
        let policy = Localization.commonPrivacyPolicy

        func makeBaseAttributedString(for text: String) -> AttributedString {
            var attributedString = AttributedString(text)
            attributedString.font = Fonts.Regular.footnote
            attributedString.foregroundColor = Colors.Text.tertiary
            return attributedString
        }

        func formatLink(in attributedString: inout AttributedString, textToSearch: String, url: URL) {
            guard let range = attributedString.range(of: textToSearch) else {
                return
            }

            attributedString[range].link = url
            attributedString[range].foregroundColor = Colors.Text.accent
        }

        var attributedString = makeBaseAttributedString(for: Localization.stakingLegal(tos, policy))
        formatLink(in: &attributedString, textToSearch: tos, url: Constants.tosURL)
        formatLink(in: &attributedString, textToSearch: policy, url: Constants.privacyPolicyURL)
        return attributedString
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

extension StakingAction.ActionType {
    var title: String {
        switch self {
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .pending(.withdraw): Localization.stakingWithdraw
        case .pending(.claimRewards): Localization.commonClaimRewards
        case .pending(.restakeRewards): Localization.stakingRestakeRewards
        case .pending(.voteLocked): Localization.stakingVote
        case .pending(.unlockLocked): Localization.stakingUnlockedLocked
        }
    }
}

extension StakingDetailsViewModel {
    enum Constants {
        static let tosURL = URL(string: "https://docs.stakek.it/docs/terms-of-use")!
        static let privacyPolicyURL = URL(string: "https://docs.stakek.it/docs/privacy-policy")!
    }
}
