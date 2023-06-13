//
//  LegacyMainCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class LegacyMainCoordinator: CoordinatorObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var mainViewModel: LegacyMainViewModel? = nil

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var pushTxCoordinator: PushTxCoordinator? = nil
    @Published var tokenDetailsCoordinator: LegacyTokenDetailsCoordinator? = nil
    @Published var detailsCoordinator: DetailsCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil

    // MARK: - Child view models

    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil
    @Published var addressQrBottomSheetContentViewModel: AddressQrBottomSheetContentViewModel? = nil
    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil
    @Published var userWalletListCoordinator: UserWalletListCoordinator?
    @Published var promotionCoordinator: PromotionCoordinator?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    private var lastInsertedUserWalletId: Data?
    private var bag: Set<AnyCancellable> = []

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                guard let self else { return }

                switch event {
                case .selected(let userWallet, _):
                    guard !userWallet.isLocked,
                          let selectedModel = userWalletRepository.selectedModel
                    else {
                        return
                    }

                    let options = Options(cardModel: selectedModel)
                    start(with: options)
                case .inserted(let userWallet):
                    lastInsertedUserWalletId = userWallet.userWalletId
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    func start(with options: LegacyMainCoordinator.Options) {
        Analytics.log(.walletOpened)

        mainViewModel = LegacyMainViewModel(
            cardModel: options.cardModel,
            cardImageProvider: CardImageProvider(supportsOnlineImage: options.cardModel.supportsOnlineImage),
            coordinator: self
        )
    }
}

extension LegacyMainCoordinator {
    struct Options {
        let cardModel: CardViewModel

        init(cardModel: CardViewModel) {
            self.cardModel = cardModel
        }
    }
}

extension LegacyMainCoordinator: LegacyMainRoutable {
    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
            self?.mainViewModel?.updateIsBackupAllowed()
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
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

    func openExplorer(at url: URL, blockchainDisplayName: String) {
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.commonExplorerFormat(blockchainDisplayName),
            withCloseButton: true
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

    func openPushTx(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.pushTxCoordinator = nil
        }

        let coordinator = PushTxCoordinator(dismissAction: dismissAction)
        let options = PushTxCoordinator.Options(
            tx: tx,
            blockchainNetwork: blockchainNetwork,
            cardModel: card
        )
        coordinator.start(with: options)
        pushTxCoordinator = coordinator
    }

    func close(newScan: Bool) {
        popToRoot(with: .init(newScan: newScan))
    }

    func openSettings(cardModel: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.detailsCoordinator = nil
        }

        let coordinator = DetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = DetailsCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        coordinator.popToRootAction = popToRootAction
        detailsCoordinator = coordinator
    }

    func openTokenDetails(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType) {
        Analytics.log(.tokenIsTapped)
        let dismissAction: Action = { [weak self] in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = LegacyTokenDetailsCoordinator(dismissAction: dismissAction)
        let options = LegacyTokenDetailsCoordinator.Options(
            cardModel: cardModel,
            blockchainNetwork: blockchainNetwork,
            amountType: amountType
        )
        coordinator.start(with: options)
        tokenDetailsCoordinator = coordinator
    }

    func openCurrencySelection(autoDismiss: Bool) {
        currencySelectViewModel = CurrencySelectViewModel()
        currencySelectViewModel?.dismissAfterSelection = autoDismiss
    }

    func openTokensList(with cardModel: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.tokenListCoordinator = nil
        }

        let coordinator = TokenListCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .add(cardModel: cardModel))
        tokenListCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openQR(shareAddress: String, address: String, qrNotice: String) {
        Analytics.log(.receiveScreenOpened)
        addressQrBottomSheetContentViewModel = .init(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
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

    func openUserWalletList() {
        let dismissAction: Action = { [weak self] in
            self?.userWalletListCoordinator = nil
        }

        let coordinator = UserWalletListCoordinator(output: self, dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start()

        userWalletListCoordinator = coordinator
    }

    /// Because `MainRoutable` inherits `TokenDetailsRoutable`. Todo: Remove it dependency
    func openSwapping(input: CommonSwappingModulesFactory.InputModel) {}

    func openPromotion(cardPublicKey: String, cardId: String, walletId: String) {
        let dismissAction: Action = { [weak self] in
            self?.promotionCoordinator = nil
        }

        let coordinator = PromotionCoordinator(dismissAction: dismissAction)
        let options: PromotionCoordinator.Options = .oldUser(cardPublicKey: cardPublicKey, cardId: cardId, walletId: walletId)
        coordinator.start(with: options)
        promotionCoordinator = coordinator
    }
}

extension LegacyMainCoordinator: UserWalletListCoordinatorOutput {
    func dismissAndOpenOnboarding(with input: OnboardingInput) {
        userWalletListCoordinator = nil

        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
            self?.userWalletRepository.updateSelection()
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.modalOnboardingCoordinator = coordinator
            Analytics.log(.onboardingStarted)
        }
    }
}
