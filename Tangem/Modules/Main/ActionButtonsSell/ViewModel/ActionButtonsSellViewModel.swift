//
//  ActionButtonsSellViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSellViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    // MARK: - Published properties

    @Published var alert: AlertBinder?

    // MARK: - Child ViewModel

    let tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    // MARK: - Private properties

    private weak var coordinator: ActionButtonsSellRoutable?

    private let userWalletModel: UserWalletModel

    init(
        tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel,
        coordinator: some ActionButtonsSellRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .onAppear:
            ActionButtonsAnalyticsService.trackScreenOpened(.sell)
        case .close:
            ActionButtonsAnalyticsService.trackCloseButtonTap(source: .sell)
            coordinator?.dismiss()
        case .didTapToken(let token):
            handleTapToken(token)
        }
    }

    private func handleTapToken(_ token: ActionButtonsTokenSelectorItem) {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(
            for: .exchange
        ) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        ActionButtonsAnalyticsService.trackTokenClicked(.sell, tokenSymbol: token.infoProvider.tokenItem.currencySymbol)

        guard let url = makeSellUrl(from: token) else { return }

        coordinator?.openSellCrypto(at: url) { response in
            self.makeSendToSellModel(from: response, and: token.walletModel)
        }
    }
}

// MARK: - Fabric methods

private extension ActionButtonsSellViewModel {
    func makeSendToSellModel(
        from response: String,
        and walletModel: WalletModel
    ) -> ActionButtonsSendToSellModel? {
        let exchangeUtility = makeExchangeCryptoUtility(for: walletModel)

        guard
            let sellCryptoRequest = exchangeUtility.extractSellCryptoRequest(from: response),
            var amountToSend = walletModel.wallet.amounts[walletModel.amountType]
        else {
            return nil
        }

        amountToSend.value = sellCryptoRequest.amount

        return .init(
            amountToSend: amountToSend,
            destination: sellCryptoRequest.targetAddress,
            tag: sellCryptoRequest.tag,
            walletModel: walletModel
        )
    }

    func makeSellUrl(from token: ActionButtonsTokenSelectorItem) -> URL? {
        let sellUrl = exchangeService.getSellUrl(
            currencySymbol: token.infoProvider.tokenItem.currencySymbol,
            amountType: token.walletModel.amountType,
            blockchain: token.walletModel.blockchainNetwork.blockchain,
            walletAddress: token.walletModel.defaultAddress
        )

        return sellUrl
    }

    func makeExchangeCryptoUtility(for walletModel: WalletModel) -> ExchangeCryptoUtility {
        return ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.defaultAddress,
            amountType: walletModel.amountType
        )
    }
}

extension ActionButtonsSellViewModel {
    enum Action {
        case onAppear
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
