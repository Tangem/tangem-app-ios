//
//  OnrampStatusInput.swift
//  TangemApp
//
//  Created by Sergey Balashov on 11.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol OnrampStatusInput: AnyObject {
    var expressTransactionId: AnyPublisher<String, Never> { get }
}
