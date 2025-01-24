//
//  ActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation

final class ActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.exchangeService)
    private var exchangeService: ExchangeService

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.hotCryptoService)
    private var hotCryptoService: HotCryptoService

    // MARK: - Published properties

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    // MARK: - Child viewModel

    let tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    // MARK: - Private property

    private weak var coordinator: ActionButtonsBuyRoutable?
    private var bag = Set<AnyCancellable>()

    private var disabledLocalizedReason: String? {
        guard
            !FeatureProvider.isAvailable(.onramp),
            let reason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange)
        else {
            return nil
        }

        return reason
    }

    private let userWalletModel: UserWalletModel

    init(
        tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel,
        coordinator: some ActionButtonsBuyRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel

        bind()
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .onAppear:
            ActionButtonsAnalyticsService.trackScreenOpened(.buy)
        case .close:
            ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
            coordinator?.dismiss()
        case .didTapToken(let token):
            handleTokenTap(token)
        case .didTapHotCrypto(let token):
            coordinator?.openAddToPortfolio(.init(token: token, userWalletName: userWalletModel.name))
        case .addToPortfolio(let token):
            addTokenToPortfolio(token)
        }
    }

    private func handleTokenTap(_ token: ActionButtonsTokenSelectorItem) {
        if let disabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: token.infoProvider.tokenItem.currencySymbol)

        openBuy(for: token.walletModel)
    }
}

// MARK: - Bind

extension ActionButtonsBuyViewModel {
    private func bind() {
        userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateHotTokens(viewModel.hotCryptoItems)
            }
            .store(in: &bag)

        hotCryptoService.hotCryptoItemsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, hotTokens in
                viewModel.updateHotTokens(hotTokens)
            }
            .store(in: &bag)
    }
}

// MARK: - Hot crypto

extension ActionButtonsBuyViewModel {
    func updateHotTokens(_ hotTokens: [HotCryptoToken]) {
        let walletModelNetworkIds = userWalletModel.walletModelsManager.walletModels.map(\.blockchainNetwork.blockchain.networkId)
        hotCryptoItems = hotTokens.filter { !walletModelNetworkIds.contains($0.networkId) }
    }

    func addTokenToPortfolio(_ token: HotCryptoToken) {
        if let disabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let tokenItemMapper = TokenItemMapper(supportedBlockchains: userWalletModel.config.supportedBlockchains)

        guard
            let mappedToken = tokenItemMapper.mapToTokenItem(
                id: token.id,
                name: token.name,
                symbol: token.symbol,
                network: .init(
                    networkId: token.networkId,
                    contractAddress: token.contractAddress,
                    decimalCount: token.decimalCount
                )
            )
        else {
            return
        }

        userWalletModel.userTokensManager.add(mappedToken) { [weak self] result in
            guard let self, result.error == nil else { return }

            handleTokenAdding(tokenItem: mappedToken)
        }
    }

    private func handleTokenAdding(tokenItem: TokenItem) {
        let walletModels = userWalletModel.walletModelsManager.walletModels

        guard
            let walletModel = walletModels.first(where: { tokenItem.id == $0.tokenItem.id }),
            canBuy(walletModel)
        else {
            coordinator?.closeAddToPortfolio()
            return
        }

        ActionButtonsAnalyticsService.hotTokenClicked(tokenSymbol: walletModel.tokenItem.currencySymbol)

        coordinator?.closeAddToPortfolio()

        openBuy(for: walletModel)
    }
}

// MARK: - Helpers

private extension ActionButtonsBuyViewModel {
    func openBuy(for walletModel: WalletModel) {
        if FeatureProvider.isAvailable(.onramp) {
            coordinator?.openOnramp(walletModel: walletModel, userWalletModel: userWalletModel)
        } else if let buyUrl = makeBuyUrl(from: walletModel) {
            coordinator?.openBuyCrypto(at: buyUrl)
        }
    }

    func canBuy(_ walletModel: WalletModel) -> Bool {
        let canOnramp = FeatureProvider.isAvailable(.onramp) && expressAvailabilityProvider.canOnramp(tokenItem: walletModel.tokenItem)
        let canBuy = !FeatureProvider.isAvailable(.onramp) && exchangeService.canBuy(
            walletModel.tokenItem.currencySymbol,
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain
        )

        return canOnramp || canBuy
    }

    func makeBuyUrl(from walletModel: WalletModel) -> URL? {
        let buyUrl = exchangeService.getBuyUrl(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain,
            walletAddress: walletModel.defaultAddress
        )

        return buyUrl
    }
}

// MARK: - Action

extension ActionButtonsBuyViewModel {
    enum Action {
        case onAppear
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
        case didTapHotCrypto(HotCryptoToken)
        case addToPortfolio(HotCryptoToken)
    }
}
