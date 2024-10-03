//
//  BlockchainAccountCreatorStub.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

struct BlockchainAccountCreatorStub: AccountCreator {
    func createAccount(blockchain: Blockchain, publicKey: Wallet.PublicKey) -> any Publisher<CreatedAccount, Error> {
        return Empty()
    }
}
