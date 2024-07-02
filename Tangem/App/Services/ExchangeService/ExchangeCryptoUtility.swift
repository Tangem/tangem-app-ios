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

    var buyAvailable: Bool {
        switch amountType {
        case .coin:
            return exchangeService.canBuy(blockchain.currencySymbol, amountType: amountType, blockchain: blockchain)
        case .token(let token):
            return exchangeService.canBuy(token.symbol, amountType: amountType, blockchain: blockchain)
        case .reserve:
            return false
        }
    }

    var sellAvailable: Bool {
        switch amountType {
        case .coin:
            return exchangeService.canSell(blockchain.currencySymbol, amountType: amountType, blockchain: blockchain)
        case .token(let token):
            return exchangeService.canSell(token.symbol, amountType: amountType, blockchain: blockchain)
        case .reserve:
            return false
        }
    }

    var buyURL: URL? {
        if blockchain.isTestnet {
            let provider = ExternalLinkProviderFactory().makeProvider(for: blockchain)
            return provider.testnetFaucetURL
        }

        switch amountType {
        case .coin:
            return exchangeService.getBuyUrl(currencySymbol: blockchain.currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: address)
        case .token(let token):
            return exchangeService.getBuyUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchain, walletAddress: address)
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
            return exchangeService.getSellUrl(currencySymbol: blockchain.currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: address)
        case .token(let token):
            return exchangeService.getSellUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchain, walletAddress: address)
        case .reserve:
            return nil
        }
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        exchangeService.extractSellCryptoRequest(from: data)
    }
}
