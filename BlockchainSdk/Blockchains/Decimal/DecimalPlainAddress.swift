//
//  DecimalPlainAddress.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DecimalPlainAddress: Address {
    let value: String
    let publicKey: Wallet.PublicKey
    let type: AddressType

    var localizedName: String {
        switch type {
        case .default:
            return Constants.mainLocalizedName
        case .legacy:
            return Constants.dscLocalizedName
        }
    }
    
    init(value: String, publicKey: Wallet.PublicKey, type: AddressType) {
        self.value = value
        self.publicKey = publicKey
        self.type = type
    }
}

extension DecimalPlainAddress {
    enum Constants {
        static let mainLocalizedName = "Main"
        static let dscLocalizedName = "DSC"
    }
}
