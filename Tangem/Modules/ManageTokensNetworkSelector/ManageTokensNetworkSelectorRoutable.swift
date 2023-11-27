//
//  ManageTokensNetworkSelectorRoutable.swift
//  Tangem
//
//  Created by skibinalexander on 21.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensNetworkSelectorRoutable: AnyObject {
    func openWalletSelector(userWallets: [UserWallet], currentUserWalletId: Data?, delegate: WalletSelectorDelegate?)
}
