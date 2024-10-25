//
//  TronNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TronNetworkProvider {
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error>
}
