//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 09/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation

final class TokenDetailsViewModel: SingleTokenBaseViewModel, ObservableObject {
    @Published var actionSheet: ActionSheetBinder?
    @Published var bannerNotificationInputs: [NotificationViewInput] = []

    private(set) var balanceWithButtonsModel: BalanceWithButtonsViewModel!
    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: walletModel.tokenItem)
    @Published private(set) var activeStakingViewData: ActiveStakingViewData?

    private weak var coordinator: TokenDetailsRoutable?
    private let bannerNotificationManager: NotificationManager?
    private let xpubGenerator: XPUBGenerator?

    private let balances = CurrentValueSubject<LoadingValue<BalanceWithButtonsViewModel.Balances>, Never>(.loading)

    private var bag = Set<AnyCancellable>()

    var iconUrl: URL? {
        guard let id = walletModel.tokenItem.id else {
            return nil
        }

        return IconURLBuilder().tokenIconURL(id: id)
    }

    var customTokenColor: Color? {
        walletModel.tokenItem.token?.customTokenColor
    }

    var canHideToken: Bool { userWalletModel.config.hasFeature(.multiCurrency) }

    var canGenerateXPUB: Bool { xpubGenerator != nil }

    var hasDotsMenu: Bool { canHideToken || canGenerateXPUB }

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        notificationManager: NotificationManager,
        bannerNotificationManager: NotificationManager?,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        xpubGenerator: XPUBGenerator?,
        coordinator: TokenDetailsRoutable,
        tokenRouter: SingleTokenRoutable
    ) {
        self.coordinator = coordinator
        self.bannerNotificationManager = bannerNotificationManager
        self.xpubGenerator = xpubGenerator
        super.init(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: notificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            tokenRouter: tokenRouter
        )
        notificationManager.setupManager(with: self)
        bannerNotificationManager?.setupManager(with: self)

        balanceWithButtonsModel = .init(
            balancesPublisher: balances.eraseToAnyPublisher(),
            buttonsPublisher: $actionButtons.eraseToAnyPublisher()
        )

        prepareSelf()
    }

    deinit {
        print("TokenDetailsViewModel deinit")
    }

    func onAppear() {
        Analytics.log(event: .detailsScreenOpened, params: [Analytics.ParameterKey.token: walletModel.tokenItem.currencySymbol])
    }

    override func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .empty:
            break
        case .openFeeCurrency:
            openFeeCurrency()
        case .swap:
            openExchange()
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .retryKaspaTokenTransaction,
             .leaveAmount,
             .openLink,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview,
             .support,
             .openCurrency:
            super.didTapNotification(with: id, action: action)
        }
    }

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
    }

    override func copyDefaultAddress() {
        super.copyDefaultAddress()
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: walletModel.tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.token.rawValue,
        ])
        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .bottom(padding: 80),
                type: .temporary()
            )
    }

    override func openMarketsTokenDetails() {
        guard isMarketsDetailsAvailable else {
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.token.rawValue,
            .token: walletModel.tokenItem.currencySymbol.uppercased(),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
        ]
        Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)
        super.openMarketsTokenDetails()
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if userWalletModel.userTokensManager.canRemove(walletModel.tokenItem) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    func generateXPUBButtonAction() {
        guard let xpubGenerator else { return }

        TangemFoundation.runTask { [weak self] in
            do {
                let xpub = try await xpubGenerator.generateXPUB()
                let viewController = await UIActivityViewController(activityItems: [xpub], applicationActivities: nil)
                AppPresenter.shared.show(viewController)
            } catch {
                let sdkError = error.toTangemSdkError()
                if !sdkError.isUserCancelled {
                    self?.alert = error.alertBinder
                }
            }
        }
    }

    private func showUnableToHideAlert() {
        let tokenName = walletModel.tokenItem.name
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            tokenName,
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsUnableHideAlertTitle(tokenName),
            message: message,
            primaryButton: .default(Text(Localization.commonOk))
        )
    }

    private func showHideWarningAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsHideAlertTitle(walletModel.tokenItem.name),
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.hideToken()
            },
            secondaryButton: .cancel()
        )
    }

    private func hideToken() {
        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.token.rawValue,
            ]
        )

        userWalletModel.userTokensManager.remove(walletModel.tokenItem)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        updateBalance(walletModelState: walletModel.state)
        tokenNotificationInputs = notificationManager.notificationInputs
        bind()
    }

    private func bind() {
        Publishers.CombineLatest(
            walletModel.walletDidChangePublisher,
            walletModel.stakingManagerStatePublisher
        )
        .filter { $1 != .loading }
        .receive(on: DispatchQueue.main)
        .receiveValue { [weak self] newState, _ in
            AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
            self?.updateBalance(walletModelState: newState)
        }
        .store(in: &bag)

        pendingExpressTransactionsManager
            .pendingTransactionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, pendingTxs in
                let factory = PendingExpressTransactionsConverter()

                return factory.convertToTokenDetailsPendingTxInfo(
                    pendingTxs,
                    tapAction: weakify(viewModel, forFunction: TokenDetailsViewModel.didTapPendingExpressTransaction(with:))
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.pendingExpressTransactions, on: self, ownership: .weak)
            .store(in: &bag)

        bannerNotificationManager?.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.bannerNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        walletModel.stakingManagerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                AppLog.shared.debug("Token details receive new StakingManager state: \(state)")
                self?.updateStaking(state: state)
            }
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created, .loading:
            balances.send(.loading)
        case .idle, .noAccount:
            balances.send(.loaded(.init(all: walletModel.allBalanceFormatted, available: walletModel.availableBalanceFormatted)))
        case .failed(let message):
            balances.send(.failedToLoad(error: message))
        case .noDerivation:
            // User can't reach this screen without derived keys
            balances.send(.failedToLoad(error: CommonError.notImplemented))
        }
    }

    private func updateStaking(state: StakingManagerState) {
        switch state {
        case .loading:
            // Do nothing
            break
        case .availableToStake, .notEnabled:
            activeStakingViewData = nil
        case .loadingError, .temporaryUnavailable:
            activeStakingViewData = .init(balance: .loadingError, rewards: .none)
        case .staked(let staked):
            let rewards: ActiveStakingViewData.RewardsState? = {
                switch (staked.yieldInfo.rewardClaimingType, walletModel.stakedRewards.fiat) {
                case (.auto, _):
                    return nil
                case (.manual, .none):
                    return .noRewards
                case (.manual, .some):
                    return .rewardsToClaim(walletModel.stakedRewardsFormatted.fiat)
                }
            }()

            activeStakingViewData = ActiveStakingViewData(
                balance: .balance(walletModel.stakedWithPendingBalanceFormatted, action: { [weak self] in
                    self?.openStaking()
                }),
                rewards: rewards
            )
        }
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func dismiss() {
        coordinator?.dismiss()
    }

    func openFeeCurrency() {
        guard let feeCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem == walletModel.feeTokenItem
        }) else {
            assertionFailure("Fee currency '\(walletModel.feeTokenItem.name)' for currency '\(walletModel.tokenItem.name)' not found")
            return
        }

        coordinator?.openFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

// MARK: - SingleTokenNotificationManagerInteractionDelegate protocol conformance

extension TokenDetailsViewModel: SingleTokenNotificationManagerInteractionDelegate {
    func confirmDiscardingUnfulfilledAssetRequirements(
        with configuration: TokenNotificationEvent.UnfulfilledRequirementsConfiguration,
        confirmationAction: @escaping () -> Void
    ) {
        let alertBuilder = SingleTokenAlertBuilder()
        alert = alertBuilder.fulfillAssetRequirementsDiscardedAlert(confirmationAction: confirmationAction)
    }
}
