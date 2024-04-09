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
    var userInputAmountValue: Amount? { .init(type: .coin, currencySymbol: "$", value: 1_000_000, decimals: 0) }
    var amountError: AnyPublisher<Error?, Never> {
        Just("Insufficient funds for transfer").eraseToAnyPublisher()
    }

    func setAmount(_ decimal: Decimal?) {}
    func didChangeFeeInclusion(_ isFeeIncluded: Bool) {}
}
