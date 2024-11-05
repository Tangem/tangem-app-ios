//
//  RosettaBody.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct RosettaAddressBody: Codable {
    let networkIdentifier: RosettaNetworkIdentifier
    let accountIdentifier: RosettaAccountIdentifier
}

struct RosettaSubmitBody: Codable {
    let networkIdentifier: RosettaNetworkIdentifier
    let signedTransaction: String
}
