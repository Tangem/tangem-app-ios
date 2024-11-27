//
//  CombinedExchangeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol CombinedExchangeService {
    var sellInitializationPublisher: Published<ExchangeServiceState>.Publisher { get }
    var buyInitializationPublisher: Published<ExchangeServiceState>.Publisher { get }
}

class CommonCombinedExpressService {
    private var buyService: ExchangeService
    private let sellService: ExchangeService

    private let utorgService: UtorgService?

    init(buyService: MercuryoService, utorgService: UtorgService?, sellService: ExchangeService) {
        self.buyService = buyService
        self.utorgService = utorgService
        self.sellService = sellService
    }
}

extension CommonCombinedExpressService: ExchangeService, CombinedExchangeService {
    var sellInitializationPublisher: Published<ExchangeServiceState>.Publisher {
        sellService.initializationPublisher
    }

    var buyInitializationPublisher: Published<ExchangeServiceState>.Publisher {
        buyService.initializationPublisher
    }

    var initializationPublisher: Published<ExchangeServiceState>.Publisher {
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

    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        buyService.getBuyUrl(currencySymbol: currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: walletAddress)
    }

    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        sellService.getSellUrl(currencySymbol: currencySymbol, amountType: amountType, blockchain: blockchain, walletAddress: walletAddress)
    }

    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        sellService.extractSellCryptoRequest(from: data)
    }

    func initialize() {
        buyService.initialize()
        sellService.initialize()
        utorgService?.initialize()
        AppLog.shared.debug("CombinedExchangeService initialized")
    }
}
