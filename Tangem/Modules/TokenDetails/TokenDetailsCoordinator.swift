//
//  TokenDetailsCoordinator.swift
//  Tangem
//
//  Created by Andrew Son on 09/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var tokenDetailsViewModel: TokenDetailsViewModel? = nil

    // MARK: - Child coordinators

    @Published var legacySendCoordinator: LegacySendCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil

    // MARK: - Child view models

    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel? = nil
    @Published var pendingExpressTxStatusBottomSheetViewModel: PendingExpressTxStatusBottomSheetViewModel? = nil

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let exchangeUtility = ExchangeCryptoUtility(
            blockchain: options.walletModel.blockchainNetwork.blockchain,
            address: options.walletModel.wallet.address,
            amountType: options.walletModel.amountType
        )

        let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userId: options.userWalletModel.userWalletId.stringValue,
            logger: AppLog.shared
        )

        let expressDestinationService = CommonExpressDestinationService(
            walletModelsManager: options.userWalletModel.walletModelsManager,
            expressRepository: CommonExpressRepository(walletModelsManager: options.userWalletModel.walletModelsManager, expressAPIProvider: provider)
        )

        let notificationManager = SingleTokenNotificationManager(
            walletModel: options.walletModel,
            walletModelsManager: options.userWalletModel.walletModelsManager,
            expressDestinationService: expressDestinationService,
            contextDataProvider: options.userWalletModel
        )

        let tokenRouter = SingleTokenRouter(
            userWalletModel: options.userWalletModel,
            coordinator: self
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: options.userWalletModel.userWalletId.stringValue,
            walletModel: options.walletModel
        )

        tokenDetailsViewModel = .init(
            userWalletModel: options.userWalletModel,
            walletModel: options.walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: notificationManager,
            pendingExpressTransactionsManager: pendingExpressTransactionsManager,
            coordinator: self,
            tokenRouter: tokenRouter
        )
    }
}

// MARK: - Options

extension TokenDetailsCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
        let walletModel: WalletModel
        let userTokensManager: UserTokensManager
    }
}

// MARK: - TokenDetailsRoutable

extension TokenDetailsCoordinator: TokenDetailsRoutable {
    func openPendingExpressTransactionDetails(
        for pendingTransaction: PendingExpressTransaction,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheetViewModel = .init(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            pendingTransactionsManager: pendingTransactionsManager,
            router: self
        )
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension TokenDetailsCoordinator: PendingExpressTxStatusRoutable {
    func openPendingExpressTxStatus(at url: URL) {
        safariManager.openURL(url)
    }
}

extension TokenDetailsCoordinator: SingleTokenBaseRoutable {
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

    func openFeeCurrency(for model: WalletModel, userWalletModel: UserWalletModel) {
        // TODO: Remove this stuff after Send screen refactoring
        guard model.tokenItem != tokenDetailsViewModel?.walletModel.tokenItem else {
            return
        }

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

    func openSellCrypto(at url: URL, action: @escaping (String) -> Void) {
        Analytics.log(.withdrawScreenOpened)

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil
            action(closeURL.absoluteString)
        }
    }

    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, userWalletModel: UserWalletModel, walletModel: WalletModel) {
        guard FeatureProvider.isAvailable(.sendV2) else {
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
        guard FeatureProvider.isAvailable(.sendV2) else {
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
}
