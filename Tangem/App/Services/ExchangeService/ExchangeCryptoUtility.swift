//
//  ExchangeCryptoUtility.swift
//  Tangem
//
//  Created by Andrew Son on 15/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ExchangeCryptoUtility {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    private let blockchain: Blockchain
    private let address: String
    private let amountType: Amount.AmountType

    init(blockchain: Blockchain, address: String, amountType: Amount.AmountType) {
        self.blockchain = blockchain
        self.address = address
        self.amountType = amountType
    }

    var buyAvailable: Bool { buyURL != nil }
    var sellAvailable: Bool { sellURL != nil }

    var buyURL: URL? {
        if blockchain.isTestnet {
            return blockchain.testnetFaucetURL
        }

        switch amountType {
        case .coin:
            return exchangeService.getBuyUrl(currencySymbol: blockchain.currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: address, useDarkTheme: useDarkTheme)
        case .token(let token):
            return exchangeService.getBuyUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchain, walletAddress: address, useDarkTheme: useDarkTheme)
        case .reserve:
            return nil
        }
    }

    var buyCryptoCloseURL: String {
        exchangeService.successCloseUrl.removeLatestSlash()
    }

    var sellURL: URL? {
        switch amountType {
        case .coin:
            return exchangeService.getSellUrl(currencySymbol: blockchain.currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: address, useDarkTheme: useDarkTheme)
        case .token(let token):
            return exchangeService.getSellUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchain, walletAddress: address, useDarkTheme: useDarkTheme)
        case .reserve:
            return nil
        }
    }

    var sellCryptoCloseURL: String {
        exchangeService.sellRequestUrl.removeLatestSlash()
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        exchangeService.extractSellCryptoRequest(from: data)
    }

    private var useDarkTheme: Bool {
        UITraitCollection.isDarkMode
    }
}
