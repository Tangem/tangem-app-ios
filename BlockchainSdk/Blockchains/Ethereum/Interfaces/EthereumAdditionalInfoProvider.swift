//
//  EthereumAdditionalInfoProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 11/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol EthereumAdditionalInfoProvider {
    func getEthTxsInfo(address: String) -> AnyPublisher<EthereumTransactionResponse, Error>
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error>
}

struct EthereumTransactionResponse {
    let balance: Decimal
    let pendingTxs: [PendingTransaction]
}
