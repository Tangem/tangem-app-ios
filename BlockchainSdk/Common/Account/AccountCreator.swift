//
//  AccountCreator.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol AccountCreator {
    func createAccount(blockchain: Blockchain, publicKey: Wallet.PublicKey) -> any Publisher<CreatedAccount, Error>
}
