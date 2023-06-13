//
//  LegacyTokenDetailsRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol LegacyTokenDetailsRoutable: AnyObject {
    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void)
    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void)
    func openExplorer(at url: URL, blockchainDisplayName: String)
    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel)
    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel)
    func openPushTx(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel)
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
    func openP2PTutorial()
    func openSwapping(input: CommonSwappingModulesFactory.InputModel)
    func dismiss()
}
