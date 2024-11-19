//
//  BitcoinScriptAddressProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 13.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol BitcoinScriptAddressProvider {
    func makeScriptAddress(from scriptHash: Data) throws -> String
}
