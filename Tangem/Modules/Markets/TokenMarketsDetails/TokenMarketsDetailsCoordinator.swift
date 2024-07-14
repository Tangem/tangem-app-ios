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

    @Published var networkSelectorViewModel: MarketsTokensNetworkSelectorViewModel? = nil
    @Published var receiveBottomSheetViewModel: ReceiveBottomSheetViewModel? = nil
    @Published var warningBankCardViewModel: WarningBankCardViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil

    @Published private(set) var tokenDetailsViewModel: TokenDetailsViewModel? = nil

    // MARK: - Child Coordiantors

    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var expressCoordinator: ExpressCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var stakingDetailsCoordinator: StakingDetailsCoordinator? = nil

    private var safariHandle: SafariHandle?

    private let portfolioCoordinatorFactory = TokenMarketsDetailsPortfolioCoodinatorFactory()

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(tokenInfo: options.info, dataProvider: .init(), coordinator: self)
    }
}

extension TokenMarketsDetailsCoordinator {
    struct Options {
        let info: MarketsTokenModel
    }
}

extension TokenMarketsDetailsCoordinator: TokenMarketsDetailsRoutable {
    func openTokenSelector(with coinModel: CoinModel, with walletDataProvider: MarketsWalletDataProvider) {
        networkSelectorViewModel = MarketsTokensNetworkSelectorViewModel(coinModel: coinModel, walletDataProvider: walletDataProvider)
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }
}

// MARK: - MarketsPortfolioContainerRoutable

extension TokenMarketsDetailsCoordinator {
    func openAddToken() {
        do {
            guard let rootViewModel else {
                assertionFailure("Root viewmodel must not be nil")
                return
            }

            let coinModel = try rootViewModel.resolveCoinModel()
            let walletDataProvider = rootViewModel.resolveWalletDataProvider()

            networkSelectorViewModel = MarketsTokensNetworkSelectorViewModel(coinModel: coinModel, walletDataProvider: walletDataProvider)
        } catch {
            assertionFailure(error.localizedDescription)
            return
        }
    }

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

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, with: navigationInfo.userWalletModel)
                }
            }
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

            guard let navigationInfo else {
                return
            }

            self?.openFeeCurrency(for: navigationInfo.walletModel, with: navigationInfo.userWalletModel)
        }

        expressCoordinator = portfolioCoordinatorFactory.makeExchangeCoordinator(
            for: walletModel,
            with: userWalletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
    }

    func openStaking(walletModel: WalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.stakingDetailsCoordinator = nil
        }

        stakingDetailsCoordinator = portfolioCoordinatorFactory.makeStakingDetailsCoordinator(
            walletModel: walletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
    }

    func openSell(for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            error = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let exchangeUtility = portfolioCoordinatorFactory.buildExchangeCryptoUtility(for: walletModel)

        guard let url = exchangeUtility.sellURL else {
            return
        }

        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            self?.safariHandle = nil

            if let request = self?.portfolioCoordinatorFactory.makeSellCryptoRequest(from: closeURL, with: exchangeUtility) {
                self?.openSendToSell(with: request, for: walletModel, with: userWalletModel)
            }
        }
    }

    func openSendToSell(with request: SellCryptoRequest, for walletModel: WalletModel, with userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, with: navigationInfo.userWalletModel)
                }
            }
        }
    }

    func showCopyAddressAlert() {
        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .bottom(padding: 80),
                type: .temporary()
            )
    }

    func openFeeCurrency(for model: WalletModel, with userWalletModel: UserWalletModel) {
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
            url: URL(string: "https://tangem.com/howtobuy.html")!,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            urlActions: [:]
        )
    }
}
