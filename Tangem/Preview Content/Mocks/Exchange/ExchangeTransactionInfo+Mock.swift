//
//  ExchangeTransactionDataModel+Mock.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

extension ExchangeTransactionDataModel {
    static let mock = ExchangeTransactionDataModel(
        sourceCurrency: .mock,
        sourceBlockchain: .ethereum,
        destinationCurrency: .mock,
        sourceAddress: "",
        destinationAddress: "",
        txData: Data(),
        sourceAmount: 123_000_000_000_000,
        destinationAmount: 300_000_000_000_000,
        value: 0,
        gas: EthereumGasDataModel(blockchain: .ethereum, gasPrice: 1_000_000_000, gasLimit: 310_000)
    )
}
