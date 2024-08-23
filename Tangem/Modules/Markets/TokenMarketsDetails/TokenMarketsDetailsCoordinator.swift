//
//  TokenMarketsDetailsCoordinator.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class TokenMarketsDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root ViewModels

    @Published var rootViewModel: TokenMarketsDetailsViewModel? = nil
    @Published var error: AlertBinder? = nil

    // MARK: - Child ViewModels

    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel? = nil
    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil

    // MARK: - Child Coordinators

    @Published var tokenNetworkSelectorCoordinator: MarketsTokenNetworkSelectorCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil

    private var safariHandle: SafariHandle?

    private let portfolioCoordinatorFactory = MarketsTokenDetailsPortfolioCoordinatorFactory()

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(
            tokenInfo: options.info,
            dataProvider: .init(),
            marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(),
            coordinator: self
        )
    }
}

extension TokenMarketsDetailsCoordinator {
    struct Options {
        let info: MarketsTokenModel
    }
}

extension TokenMarketsDetailsCoordinator: TokenMarketsDetailsRoutable {
    func openTokenSelector(with coinModel: CoinModel, with walletDataProvider: MarketsWalletDataProvider) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenNetworkSelectorCoordinator = nil
        }

        tokenNetworkSelectorCoordinator = MarketsTokenNetworkSelectorCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        tokenNetworkSelectorCoordinator?.start(with: .init(coinModel: coinModel, walletDataProvider: walletDataProvider))
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func closeModule() {
        dismiss()
    }
}

// MARK: - MarketsPortfolioContainerRoutable

extension TokenMarketsDetailsCoordinator {
    func openReceive(walletModel: WalletModel) {
        let infos = walletModel.wallet.addresses.map { address in
            ReceiveAddressInfo(
                address: address.value,
                type: address.type,
                localizedName: address.localizedName,
                addressQRImage: QrCodeGenerator.generateQRCode(from: address.value)
            )
        }

        receiveBottomSheetViewModel = .init(tokenItem: walletModel.tokenItem, addressInfos: infos)
    }

    func openBuyCryptoIfPossible(for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard let url = portfolioCoordinatorFactory.makeBuyURL(for: walletModel, with: userWalletModel) else {
            return
        }

        if portfolioCoordinatorFactory.canBuy {
            openBuyCrypto(at: url, with: walletModel)
        } else {
            openBankWarning { [weak self] in
                self?.openBuyCrypto(at: url, with: walletModel)
            } declineCallback: { [weak self] in
                self?.openP2PTutorial()
            }
        }
    }

    func openSend(for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil
        }

        sendCoordinator = portfolioCoordinatorFactory.makeSendCoordinator(
            for: walletModel,
            with: userWalletModel,
            dismissAction: dismissAction
        )
    }

    func openExchange(for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.expressCoordinator = nil
        }

        expressCoordinator = portfolioCoordinatorFactory.makeExpressCoordinator(
            for: walletModel,
            with: userWalletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
    }

    func openStaking(for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        stakingDetailsCoordinator = portfolioCoordinatorFactory.makeStakingDetailsCoordinator(
            for: walletModel,
            with: userWalletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
    }

    func openSell(for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard let url = portfolioCoordinatorFactory.makeSellURL(for: walletModel) else {
            return
        }

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil

            if let request = self?.portfolioCoordinatorFactory.makeSellCryptoRequest(from: closeURL, with: walletModel) {
                self?.openSendToSell(with: request, for: walletModel, with: userWalletModel)
            }
        }
    }

    func openSendToSell(with request: SellCryptoRequest, for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil
        }

        sendCoordinator = portfolioCoordinatorFactory.makeSendCoordinator(
            for: walletModel,
            with: userWalletModel,
            dismissAction: dismissAction
        )
    }
}

// MARK: - Utilities functions

extension TokenMarketsDetailsCoordinator {
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

    func openBuyCrypto(at url: URL, with walletModel: WalletModel) {
        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                walletModel.update(silent: true)
            }
        }
    }

    func openP2PTutorial() {
        modalWebViewModel = WebViewContainerViewModel(
            url: AppConstants.howToBuyURL,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            urlActions: [:]
        )
    }
}
