//
//  IdentityEthereumAddressConverter.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct IdentityEthereumAddressConverter: EthereumAddressConverter {
    func convertToETHAddress(_ address: String) throws -> String {
        return address
    }
}
