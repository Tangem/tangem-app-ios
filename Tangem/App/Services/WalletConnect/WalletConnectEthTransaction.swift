//
//  WalletConnectEthTransaction.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.04.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectEthTransaction: Codable {
    let from: String // Required
    let to: String // Required
    let value: String? // Required
    let data: String // Required
    let gas: String?
    let gasLimit: String?
    let gasPrice: String?
    let nonce: String?

    var description: String {
        return """
        to: \(to),
        value: \(value ?? "0"),
        gasPrice: \(gasPrice ?? "not specified"),
        gas: \(gas ?? gasLimit ?? "not specified"),
        data: \(data.count > 30 ? "\(data.prefix(10))...\(data.suffix(10))" : data),
        nonce: \(nonce ?? "not specified")
        """
    }
}
