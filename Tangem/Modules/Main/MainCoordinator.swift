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

class MainCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var legacySendCoordinator: LegacySendCoordinator?
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var swappingCoordinator: SwappingCoordinator?
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var legacyTokenListCoordinator: LegacyTokenListCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var warningBankCardViewModel: WarningBankCardViewModel?
    @Published var modalWebViewModel: WebViewContainerViewModel?
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?
    @Published var organizeTokensViewModel: OrganizeTokensViewModel? = nil

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

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
        // TODO: Remove this stuff after Send screen refactoring
        guard let cardViewModel = userWalletModel as? CardViewModel else {
            return
        }

        Analytics.log(.tokenIsTapped)
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                cardModel: cardViewModel,
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

// MARK: - SingleTokenRoutable

extension MainCoordinator: SingleTokenBaseRoutable {
    func openReceiveScreen(amountType: Amount.AmountType, blockchain: Blockchain, addressInfos: [ReceiveAddressInfo]) {
        let tokenItem: TokenItem
        switch amountType {
        case .token(let token):
            tokenItem = .token(token, blockchain)
        default:
            tokenItem = .blockchain(blockchain)
        }
        receiveBottomSheetViewModel = .init(tokenItem: tokenItem, addressInfos: addressInfos)
    }

    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        Analytics.log(.topupScreenOpened)
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonBuy,
            addLoadingIndicator: true,
            withCloseButton: true,
            urlActions: [
                closeUrl: { [weak self] response in
                    self?.modalWebViewModel = nil
                    action(response)
                },
            ]
        )
    }

    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonSell,
            addLoadingIndicator: true,
            withCloseButton: true,
            urlActions: [sellRequestUrl: action]
        )
    }

    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel) {
        guard FeatureProvider.isAvailable(.sendV2) else {
            let coordinator = LegacySendCoordinator { [weak self] in
                self?.legacySendCoordinator = nil
            }
            let options = LegacySendCoordinator.Options(
                amountToSend: amountToSend,
                destination: nil,
                blockchainNetwork: blockchainNetwork,
                cardViewModel: cardViewModel
            )
            coordinator.start(with: options)
            legacySendCoordinator = coordinator
            return
        }

        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }

        let options = SendCoordinator.Options(
            emailDataProvider: cardViewModel,
            walletModel: walletModel,
            transactionSigner: cardViewModel.signer,
            type: .send
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel, walletModel: WalletModel) {
        guard FeatureProvider.isAvailable(.sendV2) else {
            let coordinator = LegacySendCoordinator { [weak self] in
                self?.legacySendCoordinator = nil
            }
            let options = LegacySendCoordinator.Options(
                amountToSend: amountToSend,
                destination: destination,
                blockchainNetwork: blockchainNetwork,
                cardViewModel: cardViewModel
            )
            coordinator.start(with: options)
            legacySendCoordinator = coordinator
            return
        }

        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(
            emailDataProvider: cardViewModel,
            walletModel: walletModel,
            transactionSigner: cardViewModel.signer,
            type: .sell(amount: amountToSend, destination: destination)
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

    func openSwapping(input: CommonSwappingModulesFactory.InputModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.swappingCoordinator = nil
        }

        let factory = CommonSwappingModulesFactory(inputModel: input)
        let coordinator = SwappingCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        swappingCoordinator = coordinator
    }

    func openExpress(input: CommonExpressModulesFactory.InputModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.expressCoordinator = nil

            guard let navigationInfo else {
                return
            }

            self?.openNetworkCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
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

    func openExplorer(at url: URL, blockchainDisplayName: String) {
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(blockchainDisplayName),
            withCloseButton: true
        )
    }

    func openNetworkCurrency(for model: WalletModel, userWalletModel: UserWalletModel) {
        // TODO: Remove this stuff after Send screen refactoring
        guard let cardViewModel = userWalletModel as? CardViewModel else {
            return
        }

        #warning("TODO: Add analytics")
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                cardModel: cardViewModel,
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
