//
//  ExpressModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol ExpressModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel
    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel

    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeSelectorRoutable) -> ExpressFeeSelectorViewModel
    func makeExpressApproveViewModel(
        providerName: String,
        selectedPolicy: ExpressApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel

    func makeExpressProvidersSelectorViewModel(coordinator: ExpressProvidersSelectorRoutable) -> ExpressProvidersSelectorViewModel

    func makeExpressSuccessSentViewModel(
        data: SentExpressTransactionData,
        coordinator: ExpressSuccessSentRoutable
    ) -> ExpressSuccessSentViewModel

    func makePendingExpressTransactionsManager() -> PendingExpressTransactionsManager
}
