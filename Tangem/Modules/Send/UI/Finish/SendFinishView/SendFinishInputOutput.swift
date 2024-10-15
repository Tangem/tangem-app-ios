//
//  SendFinishInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFinishInput: AnyObject {
    var transactionSentDate: AnyPublisher<Date, Never> { get }
}
