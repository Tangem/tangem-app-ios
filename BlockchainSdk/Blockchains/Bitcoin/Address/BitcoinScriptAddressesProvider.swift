//
//  BitcoinScriptAddressProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol BitcoinScriptAddressesProvider {
    func makeAddresses(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> [BitcoinScriptAddress]
}
