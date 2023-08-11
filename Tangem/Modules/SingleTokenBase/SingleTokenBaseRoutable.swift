//
//  SingleTokenBaseRoutable.swift
//  Tangem
//
//  Created by Andrew Son on 07/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

protocol SingleTokenBaseRoutable: AnyObject {
    func openReceiveScreen(amountType: Amount.AmountType, blockchain: Blockchain, addressInfos: [ReceiveAddressInfo])
    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void)
    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void)
    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel)
    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel)
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
    func openP2PTutorial()
    func openSwapping(input: CommonSwappingModulesFactory.InputModel)
    func openExplorer(at url: URL, blockchainDisplayName: String)
}
