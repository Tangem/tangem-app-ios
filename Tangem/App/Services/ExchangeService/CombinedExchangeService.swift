//
//  CombinedExchangeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CombinedExchangeService {
    private var buyService: ExchangeService
    private let sellService: ExchangeService

    private let mercuryoService: MercuryoService
    private let utorgService: UtorgService?

    init(mercuryoService: MercuryoService, utorgService: UtorgService?, sellService: ExchangeService) {
        buyService = mercuryoService
        self.mercuryoService = mercuryoService
        self.utorgService = utorgService
        self.sellService = sellService
    }
}

extension CombinedExchangeService: ExchangeService {
    var initializationPublisher: Published<Bool>.Publisher {
        buyService.initializationPublisher
    }

    var successCloseUrl: String {
        buyService.successCloseUrl
    }

    var sellRequestUrl: String {
        sellService.sellRequestUrl
    }

    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        buyService.canBuy(currencySymbol, amountType: amountType, blockchain: blockchain)
    }

    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        sellService.canSell(currencySymbol, amountType: amountType, blockchain: blockchain)
    }

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String, useDarkTheme: Bool) -> URL? {
        buyService.getBuyUrl(currencySymbol: currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: walletAddress, useDarkTheme: useDarkTheme)
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String, useDarkTheme: Bool) -> URL? {
        sellService.getSellUrl(currencySymbol: currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: walletAddress, useDarkTheme: useDarkTheme)
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        sellService.extractSellCryptoRequest(from: data)
    }

    func initialize() {
        mercuryoService.initialize()
        sellService.initialize()
        utorgService?.initialize()
        AppLog.shared.debug("CombinedExchangeService initialized")
    }
}
