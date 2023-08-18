//
//  WalletManagerFactoryProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class WalletManagerFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    lazy var factory: WalletManagerFactory = .init(config: keysManager.blockchainConfig)

    init() {}
}
