//
//  TONTransactionParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 06.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import WalletCore

public struct TONTransactionParams: TransactionParams {
    var memo: String

    public init(memo: String) {
        self.memo = memo
    }
}
