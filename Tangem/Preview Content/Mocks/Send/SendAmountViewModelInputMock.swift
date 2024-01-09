//
//  SendAmountViewModelInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendAmountViewModelInputMock: SendAmountViewModelInput {
    var amountPublisher: AnyPublisher<BlockchainSdk.Amount?, Never> { .just(output: nil) }

    func setAmount(_ amount: BlockchainSdk.Amount?) {}

    var amountType: Amount.AmountType { .coin }

    var blockchain: Blockchain { .ethereum(testnet: false) }
    var amountError: AnyPublisher<Error?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
