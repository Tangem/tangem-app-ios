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
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var mainViewModel: MainViewModel?

    // MARK: - Child coordinators

    @Published var detailsCoordinator: DetailsCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var sendCoordinator: SendCoordinator?
    @Published var swappingCoordinator: SwappingCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var pushedWebViewModel: WebViewContainerViewModel?
    @Published var warningBankCardViewModel: WarningBankCardViewModel?
    @Published var modalWebViewModel: WebViewContainerViewModel?
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel?

    // MARK: - Other state

    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var organizeTokensViewModel: OrganizeTokensViewModel? = nil

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        mainViewModel = MainViewModel(
            selectedUserWalletId: options.userWalletModel.userWalletId,
            coordinator: self,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: self)
        )
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
    func openDetails(for cardModel: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = DetailsCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        coordinator.popToRootAction = popToRootAction
        detailsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
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
        let dismissAction: Action = { [weak self] in
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
        let userTokenListManager = userWalletModel.userTokenListManager
        let optionsManager = OrganizeTokensOptionsManager(
            userTokenListManager: userTokenListManager,
            editingThrottleInterval: 1.0
        )
        let walletModelComponentsBuilder = WalletModelComponentsBuilder(
            supportedBlockchains: userWalletModel.config.supportedBlockchains
        )
        let walletModelsAdapter = OrganizeWalletModelsAdapter(
            userTokenListManager: userTokenListManager,
            walletModelComponentsBuilder: walletModelComponentsBuilder,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )

        organizeTokensViewModel = OrganizeTokensViewModel(
            coordinator: self,
            walletModelsManager: userWalletModel.walletModelsManager,
            walletModelsAdapter: walletModelsAdapter,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )
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
        pushedWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonBuy,
            addLoadingIndicator: true,
            urlActions: [
                closeUrl: { [weak self] response in
                    self?.pushedWebViewModel = nil
                    action(response)
                },
            ]
        )
    }

    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)
        pushedWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonSell,
            addLoadingIndicator: true,
            urlActions: [sellRequestUrl: action]
        )
    }

    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(
            amountToSend: amountToSend,
            destination: nil,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardViewModel
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator { [weak self] in
            self?.sendCoordinator = nil
        }
        let options = SendCoordinator.Options(
            amountToSend: amountToSend,
            destination: destination,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardViewModel
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
        let dismissAction: Action = { [weak self] in
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

    func openExplorer(at url: URL, blockchainDisplayName: String) {
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(blockchainDisplayName),
            withCloseButton: true
        )
    }
}

// MARK: - SingleWalletMainContentRoutable protocol conformance

extension MainCoordinator: SingleWalletMainContentRoutable {}

// MARK: - OrganizeTokensRoutable protocol conformance

extension MainCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        organizeTokensViewModel = nil
    }
}
