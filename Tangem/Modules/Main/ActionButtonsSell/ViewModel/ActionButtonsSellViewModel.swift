//
//  ActionButtonsSellViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSellViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    let tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    private weak var coordinator: ActionButtonsSellRoutable?

    init(
        coordinator: some ActionButtonsSellRoutable,
        tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel
    ) {
        self.coordinator = coordinator
        self.tokenSelectorViewModel = tokenSelectorViewModel
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .close:
            coordinator?.dismiss()
        case .didTapToken(let token):
            guard let url = makeSellUrl(from: token) else { return }

            coordinator?.openSellCrypto(at: url) { response in
                self.makeSendToSellModel(from: response, and: token.walletModel)
            }
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
            currencySymbol: token.symbol,
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
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
