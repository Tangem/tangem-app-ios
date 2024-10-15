//
//  ExpressCurrency.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressCurrency: Hashable {
    public let contractAddress: String
    public let network: String

    public init(contractAddress: String, network: String) {
        self.contractAddress = contractAddress
        self.network = network
    }
}
