//
//  SendAmountInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendAmountInputOutputMock: SendAmountInput, SendAmountOutput {
    var amount: SendAmount? { .none }
    var amountPublisher: AnyPublisher<SendAmount?, Never> { .just(output: amount) }

    func amountDidChanged(amount: SendAmount?) {}
}
