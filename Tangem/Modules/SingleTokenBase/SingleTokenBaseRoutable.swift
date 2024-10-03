//
//  SingleTokenBaseRoutable.swift
//  Tangem
//
//  Created by Andrew Son on 07/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

protocol SingleTokenBaseRoutable: AnyObject {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo])
    func openBuyCrypto(at url: URL, action: @escaping () -> Void)
    func openSellCrypto(at url: URL, action: @escaping (String) -> Void)
    func openSend(userWalletModel: UserWalletModel, walletModel: WalletModel)
    func openSendToSell(amountToSend: Amount, destination: String, tag: String?, userWalletModel: UserWalletModel, walletModel: WalletModel)
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
    func openP2PTutorial()
    func openExpress(input: CommonExpressModulesFactory.InputModel)
    func openStaking(options: StakingDetailsCoordinator.Options)
    func openInSafari(url: URL)
    func openMarketsTokenDetails(tokenModel: MarketsTokenModel)
}
