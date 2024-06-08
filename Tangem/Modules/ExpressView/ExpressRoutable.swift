//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol ExpressRoutable: AnyObject {
    func presentSwappingTokenList(swapDirection: ExpressTokensListViewModel.SwapDirection)
    func presentFeeSelectorView()
    func presentApproveView()
    func presentProviderSelectorView()
    func presentFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel)
    func presentSuccessView(data: SentExpressTransactionData)
    func closeSwappingView()
}
