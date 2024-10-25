//
//  PolkadotAddress.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

struct PolkadotAddress {
    let string: String
    private let ss58 = SS58()

    init?(string: String, network: PolkadotNetwork) {
        guard ss58.isValidAddress(string, type: network.addressPrefix) else {
            return nil
        }
        self.string = string
    }

    init(publicKey: Data, network: PolkadotNetwork) {
        let accountData = ss58.accountData(from: publicKey)
        string = ss58.address(from: accountData, type: network.addressPrefix)
    }

    // Raw representation (without the prefix) was used in the older protocol versions
    func bytes(raw: Bool) -> Data? {
        ss58.bytes(string: string, raw: raw)
    }
}
