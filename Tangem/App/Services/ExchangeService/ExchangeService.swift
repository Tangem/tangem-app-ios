//
//  ExchangeService.swift
//  Tangem
//
//  Created by Andrew Son on 05/07/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

// TODO: Refactor name)
private typealias ExternalExchangeService = ExchangeService

protocol ExchangeService: AnyObject, Initializable {
    var initializationPublisher: Published<Bool>.Publisher { get }
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String, useDarkTheme: Bool) -> URL?
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String, useDarkTheme: Bool) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

private struct ExchangeServiceKey: InjectionKey {
    static var currentValue: ExternalExchangeService = CombinedExchangeService(
        mercuryoService: MercuryoService(),
        utorgService: nil, // Remove optional from the ExternalExchangeService and set the utorgSID in the CommonKeysManager tore-integrate Utorg
        sellService: MoonPayService()
    )
}

extension InjectedValues {
    var exchangeService: ExchangeService {
        externalExchangeService
    }

    // TODO: Make not private because we can't mock this services. For now it's ok, but later it should be updated.
    private var externalExchangeService: ExternalExchangeService {
        get { Self[ExchangeServiceKey.self] }
        set { Self[ExchangeServiceKey.self] = newValue }
    }
}
