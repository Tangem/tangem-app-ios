//
//  MainCoordinator.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk
import TangemVisa
import SwiftUI

class MainCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators (Push presentation)

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var marketsTokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator?

    // MARK: - Child coordinators (Other)

    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var actionButtonsBuyCoordinator: ActionButtonsBuyCoordinator? = nil
    @Published var actionButtonsSellCoordinator: ActionButtonsSellCoordinator? = nil
    @Published var actionButtonsSwapCoordinator: ActionButtonsSwapCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var modalWebViewModel: WebViewContainerViewModel?
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?
    @Published var organizeTokensViewModel: OrganizeTokensViewModel?
    @Published var pushNotificationsViewModel: PushNotificationsPermissionRequestViewModel?
    @Published var visaTransactionDetailsViewModel: VisaTransactionDetailsViewModel?
    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var isAppStoreReviewRequested = false
    @Published var isMarketsTooltipVisible = false

    private var safariHandle: SafariHandle?
    private var pushNotificationsViewModelSubscription: AnyCancellable?

    private let tooltipStorageProvider = TooltipStorageProvider()

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let swipeDiscoveryHelper = WalletSwipeDiscoveryHelper()
        let factory = PushNotificationsHelpersFactory()
        let pushNotificationsAvailabilityProvider = factory.makeAvailabilityProviderForAfterLogin(using: pushNotificationsInteractor)
        let viewModel = MainViewModel(
            selectedUserWalletId: options.userWalletModel.userWalletId,
            coordinator: self,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: self),
            pushNotificationsAvailabilityProvider: pushNotificationsAvailabilityProvider
        )

        swipeDiscoveryHelper.delegate = viewModel
        mainViewModel = viewModel

        setupUI()
        bind()
    }

    func hideMarketsTooltip() {
        tooltipStorageProvider.marketsTooltipWasShown = true

        withAnimation(.easeInOut(duration: Constants.tooltipAnimationDuration)) {
            isMarketsTooltipVisible = false
        }
    }

    // MARK: - Private Implementation

    private func bind() {
        guard pushNotificationsViewModelSubscription == nil else {
            return
        }

        pushNotificationsViewModelSubscription = $pushNotificationsViewModel
            .pairwise()
            .filter { previous, current in
                // Transition from a non-nil value to a nil value, i.e. dismissing the sheet
                previous != nil && current == nil
            }
            .sink { previous, _ in
                previous?.didDismissSheet()
            }
    }

    private func setupUI() {
        showMarketsTooltip()
    }

    private func showMarketsTooltip() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tooltipAnimationDelay) { [weak self] in
            guard let self else {
                self?.isMarketsTooltipVisible = false
                return
            }

            withAnimation(.easeInOut(duration: Constants.tooltipAnimationDuration)) {
                self.isMarketsTooltipVisible = !self.tooltipStorageProvider.marketsTooltipWasShown
            }
        }
    }
}

// MARK: - Options

extension MainCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}

// MARK: - MainRoutable protocol conformance

extension MainCoordinator: MainRoutable {
    func openDetails(for userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .default)
        detailsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.modalOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func close(newScan: Bool) {
        popToRoot(with: .init(newScan: newScan))
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openPushNotificationsAuthorization() {
        let factory = PushNotificationsHelpersFactory()
        let permissionManager = factory.makePermissionManagerForAfterLogin(using: pushNotificationsInteractor)
        pushNotificationsViewModel = PushNotificationsPermissionRequestViewModel(permissionManager: permissionManager, delegate: self)
    }
}

// MARK: - MultiWalletMainContentRoutable protocol conformance

extension MainCoordinator: MultiWalletMainContentRoutable {
    func openTokenDetails(for model: WalletModel, userWalletModel: UserWalletModel) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func openOrganizeTokens(for userWalletModel: UserWalletModel) {
        let optionsManager = OrganizeTokensOptionsManager(userTokensReorderer: userWalletModel.userTokensManager)
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: true
        )

        organizeTokensViewModel = OrganizeTokensViewModel(
            coordinator: self,
            userWalletModel: userWalletModel,
            tokenSectionsAdapter: tokenSectionsAdapter,
            optionsProviding: optionsManager,
            optionsEditing: optionsManager
        )
    }
}

// MARK: - SingleTokenBaseRoutable

extension MainCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        receiveBottomSheetViewModel = .init(
            tokenItem: tokenItem,
            addressInfos: addressInfos,
            hasMemo: tokenItem.blockchain.hasMemo
        )
    }

    func openBuyCrypto(at url: URL, action: @escaping () -> Void) {
        Analytics.log(.topupScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil
            action()
        }
    }

    func openSellCrypto(at url: URL, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil
            action(closeURL.absoluteString)
        }
    }

    func openSend(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
                }
            }
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .send,
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Amount, destination: String, tag: String?, userWalletModel: UserWalletModel, walletModel: WalletModel) {
        guard SendFeatureProvider.shared.isAvailable else {
            return
        }

        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
                }
            }
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .sell(parameters: .init(amount: amountToSend.value, destination: destination, tag: tag)),
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openExpress(input: CommonExpressModulesFactory.InputModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.expressCoordinator = nil

            guard let navigationInfo else {
                return
            }

            self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
        }

        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        expressCoordinator = coordinator
    }

    func openStaking(options: StakingDetailsCoordinator.Options) {
        mainBottomSheetUIManager.hide()

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        let coordinator = StakingDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        stakingDetailsCoordinator = coordinator
    }

    func openInSafari(url: URL) {
        safariManager.openURL(url)
    }

    func openFeeCurrency(for model: WalletModel, userWalletModel: UserWalletModel) {
        #warning("TODO: Add analytics")
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func openMarketsTokenDetails(tokenModel: MarketsTokenModel) {
        mainBottomSheetUIManager.hide()

        let coordinator = MarketsTokenDetailsCoordinator()
        coordinator.start(with: .init(info: tokenModel, style: .defaultNavigationStack))

        marketsTokenDetailsCoordinator = coordinator
    }

    func openOnramp(walletModel: WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] _ in
            self?.sendCoordinator = nil
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .onramp,
            source: .main
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        userWalletModel: UserWalletModel,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheetViewModel = PendingExpressTxStatusBottomSheetViewModel(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            userWalletModel: userWalletModel,
            pendingTransactionsManager: pendingTransactionsManager,
            router: self
        )
    }
}

// MARK: - OrganizeTokensRoutable protocol conformance

extension MainCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        organizeTokensViewModel = nil
    }

    func didTapSaveButton() {
        organizeTokensViewModel = nil
    }
}

// MARK: - VisaWalletRoutable

extension MainCoordinator: VisaWalletRoutable {
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord) {
        visaTransactionDetailsViewModel = .init(tokenItem: tokenItem, transaction: record)
    }
}

// MARK: - RateAppRoutable protocol conformance

extension MainCoordinator: RateAppRoutable {
    func openAppStoreReview() {
        isAppStoreReviewRequested = true
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate protocol conformance

extension MainCoordinator: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        pushNotificationsViewModel = nil
    }
}

// MARK: - Action buttons buy routable

extension MainCoordinator: ActionButtonsBuyFlowRoutable {
    func openBuy(userWalletModel: some UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.actionButtonsBuyCoordinator = nil
        }

        let coordinator = ActionButtonsBuyCoordinator(
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            dismissAction: dismissAction,
            userWalletModel: userWalletModel
        )

        coordinator.start(with: .default)

        actionButtonsBuyCoordinator = coordinator
    }
}

// MARK: - Action buttons sell routable

extension MainCoordinator: ActionButtonsSellFlowRoutable {
    func openSell(userWalletModel: some UserWalletModel) {
        let dismissAction: Action<ActionButtonsSendToSellModel?> = { [weak self] model in
            self?.actionButtonsSellCoordinator = nil

            guard let model else { return }

            self?.openSendToSell(
                amountToSend: model.amountToSend,
                destination: model.destination,
                tag: model.tag,
                userWalletModel: userWalletModel,
                walletModel: model.walletModel
            )
        }

        let coordinator = ActionButtonsSellCoordinator(
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            dismissAction: dismissAction,
            userWalletModel: userWalletModel
        )

        coordinator.start(with: .default)

        actionButtonsSellCoordinator = coordinator
    }
}

// MARK: - ActionButtonsSwapFlowRoutable

extension MainCoordinator: ActionButtonsSwapFlowRoutable {
    func openSwap(userWalletModel: some UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.actionButtonsSwapCoordinator = nil
        }

        let coordinator = ActionButtonsSwapCoordinator(
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
            userWalletModel: userWalletModel,
            dismissAction: dismissAction
        )

        coordinator.start(with: .default)

        actionButtonsSwapCoordinator = coordinator
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension MainCoordinator: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openCurrency(tokenItem: TokenItem, userWalletModel: UserWalletModel) {
        pendingExpressTxStatusBottomSheetViewModel = nil

        // We don't have info about derivation here, so we have to find first non-custom walletModel.
        guard let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain == tokenItem.blockchain
                && $0.tokenItem.token == tokenItem.token
                && !$0.isCustom
        }) else {
            return
        }

        openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
    }
}

extension MainCoordinator {
    enum Constants {
        static let tooltipAnimationDuration: Double = 0.3
        static let tooltipAnimationDelay: Double = 1.5
    }
}
