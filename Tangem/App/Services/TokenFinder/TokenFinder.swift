//
//  TokenFinder.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenFinder {
    func findToken(contractAddress: String, networkId: String) async throws -> TokenItem
}
