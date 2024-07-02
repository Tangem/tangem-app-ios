//
//  SendAmountInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendAmountInputMock: SendAmountInput {
    var amount: SendAmount? { .none }
}

class SendAmountOutputMock: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {}
}
