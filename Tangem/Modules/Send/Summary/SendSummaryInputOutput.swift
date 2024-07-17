//
//  SendSummaryInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendSummaryInput: AnyObject {
    var transactionPublisher: AnyPublisher<SendTransactionType?, Never> { get }
}

protocol SendSummaryOutput: AnyObject {}
