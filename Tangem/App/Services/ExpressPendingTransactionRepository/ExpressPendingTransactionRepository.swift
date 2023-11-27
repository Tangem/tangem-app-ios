//
//  ExpressPendingTransactionRepository.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

public protocol ExpressPendingTransactionRepository {
    func didSendApproveTransaction() // Add data
    func didSendSwapTransaction() // Add data

    func hasPending(for network: String) -> Bool
    func lastCurrencyTransaction() -> ExpressCurrency?
}
