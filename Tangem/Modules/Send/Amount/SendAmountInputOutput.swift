//
//  SendAmountInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendAmountInput: AnyObject {
    var amount: SendAmount? { get }
    var amountPublisher: AnyPublisher<SendAmount?, Never> { get }
}

protocol SendAmountOutput: AnyObject {
    func amountDidChanged(amount: SendAmount?)
}
