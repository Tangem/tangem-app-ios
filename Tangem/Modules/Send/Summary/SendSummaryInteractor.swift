//
//  SendSummaryInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendSummaryInput: AnyObject {
    var isSending: Bool { get }
}

protocol SendSummaryOutput: AnyObject {}

protocol SendSummaryInteractor: AnyObject {
    var isSending: AnyPublisher<Bool, Never> { get }
}
