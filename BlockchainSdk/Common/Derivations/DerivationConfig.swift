//
//  DerivationConfig.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public protocol DerivationConfig {
    func derivationPath(for blockchain: Blockchain) -> String
}

extension DerivationConfig {
    func derivationPath(for blockchain: Blockchain) -> DerivationPath {
        try! DerivationPath(rawPath: derivationPath(for: blockchain))
    }
}
