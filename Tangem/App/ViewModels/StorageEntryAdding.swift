//
//  StorageEntryAdding.swift
//  Tangem
//
//  Created by Andrey Chukavin on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk

protocol StorageEntryAdding {
    func getBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork
    func add(entry: StorageEntry) async throws -> String
}
