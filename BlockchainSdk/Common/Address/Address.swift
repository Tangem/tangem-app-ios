//
//  Address.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol Address {
    var value: String { get }
    var localizedName: String { get }
    var type: AddressType { get }
    var publicKey: Wallet.PublicKey { get }
}
