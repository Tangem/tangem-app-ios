//
//  ExchangeService.swift
//  Tangem
//
//  Created by Andrew Son on 05/07/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol ExchangeService: AnyObject, Initializable {
    var initializationPublisher: Published<Bool>.Publisher { get }
    var successCloseUrl: String { get }
    var sellRequestUrl: String { get }
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool
    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL?
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest?
}

private struct ExchangeServiceKey: InjectionKey {
    static var currentValue: ExchangeService = CombinedExchangeService(
        mercuryoService: MercuryoService(),
        utorgService: nil, // Remove optional from the ExchangeService and set the utorgSID in the CommonKeysManager tore-integrate Utorg
        sellService: MoonPayService()
    )
}

extension InjectedValues {
    var exchangeService: ExchangeService {
        get { Self[ExchangeServiceKey.self] }
        set { Self[ExchangeServiceKey.self] = newValue }
    }
}
