//
//  MainCoordinator.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa

class MainCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var legacySendCoordinator: LegacySendCoordinator?
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var legacyTokenListCoordinator: LegacyTokenListCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var warningBankCardViewModel: WarningBankCardViewModel?
    @Published var modalWebViewModel: WebViewContainerViewModel?
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?
    @Published var organizeTokensViewModel: OrganizeTokensViewModel?
    @Published var rateAppBottomSheetViewModel: RateAppBottomSheetViewModel?

    @Published var visaTransactionDetailsViewModel: VisaTransactionDetailsViewModel? = nil

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var isAppStoreReviewRequested = false
    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let swipeDiscoveryHelper = WalletSwipeDiscoveryHelper()
        let viewModel = MainViewModel(
            selectedUserWalletId: options.userWalletModel.userWalletId,
            coordinator: self,
            swipeDiscoveryHelper: swipeDiscoveryHelper,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: self)
        )

        swipeDiscoveryHelper.delegate = viewModel
        mainViewModel = viewModel
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
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = DetailsCoordinator.Options(userWalletModel: userWalletModel)
        coordinator.start(with: options)
        coordinator.popToRootAction = popToRootAction
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
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func close(newScan: Bool) {
        popToRoot(with: .init(newScan: newScan))
    }
}

// MARK: - MultiWalletMainContentRoutable protocol conformance

extension MainCoordinator: MultiWalletMainContentRoutable {
    func openTokenDetails(for model: WalletModel, userWalletModel: UserWalletModel) {
        Analytics.log(.tokenIsTapped)
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

    func openManageTokens(with settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.legacyTokenListCoordinator = nil
        }

        let coordinator = LegacyTokenListCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .add(
            settings: settings,
            userTokensManager: userTokensManager
        ))
        legacyTokenListCoordinator = coordinator
    }
}

// MARK: - SingleTokenBaseRoutable

extension MainCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        receiveBottomSheetViewModel = .init(tokenItem: tokenItem, addressInfos: addressInfos)
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

    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, userWalletModel: UserWalletModel, walletModel: WalletModel) {
        guard SendFeatureProvider.shared.isAvailable else {
            let coordinator = LegacySendCoordinator { [weak self] in
                self?.legacySendCoordinator = nil
            }
            let options = LegacySendCoordinator.Options(
                amountToSend: amountToSend,
                destination: nil,
                tag: nil,
                blockchainNetwork: blockchainNetwork,
                userWalletModel: userWalletModel
            )
            coordinator.start(with: options)
            legacySendCoordinator = coordinator
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
            walletName: userWalletModel.name,
            emailDataProvider: userWalletModel,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: userWalletModel.signer,
            type: .send
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Amount, destination: String, tag: String?, blockchainNetwork: BlockchainNetwork, userWalletModel: UserWalletModel, walletModel: WalletModel) {
        guard SendFeatureProvider.shared.isAvailable else {
            let coordinator = LegacySendCoordinator { [weak self] in
                self?.legacySendCoordinator = nil
            }
            let options = LegacySendCoordinator.Options(
                amountToSend: amountToSend,
                destination: destination,
                tag: tag,
                blockchainNetwork: blockchainNetwork,
                userWalletModel: userWalletModel
            )
            coordinator.start(with: options)
            legacySendCoordinator = coordinator
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
            walletName: userWalletModel.name,
            emailDataProvider: userWalletModel,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: userWalletModel.signer,
            type: .sell(amount: amountToSend, destination: destination, tag: tag)
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void) {
        let delay = 0.6
        warningBankCardViewModel = .init(confirmCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                confirmCallback()
            }
        }, declineCallback: { [weak self] in
            self?.warningBankCardViewModel = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                declineCallback()
            }
        })
    }

    func openP2PTutorial() {
        modalWebViewModel = WebViewContainerViewModel(
            url: URL(string: "https://tangem.com/howtobuy.html")!,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            urlActions: [:]
        )
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
    func openAppRateDialog(with viewModel: RateAppBottomSheetViewModel) {
        rateAppBottomSheetViewModel = viewModel
    }

    func closeAppRateDialog() {
        rateAppBottomSheetViewModel = nil
    }

    func openFeedbackMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        openMail(with: dataCollector, emailType: emailType, recipient: recipient)
    }

    func openAppStoreReview() {
        isAppStoreReviewRequested = true
    }
}
