//
//  Fact0rnWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 15.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class Fact0rnWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 0.000001 }
}
