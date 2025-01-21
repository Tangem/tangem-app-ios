//
//  AlephiumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// TODO: - https://tangem.atlassian.net/browse/IOS-8988
final class AlephiumTransactionBuilder {
    // MARK: - Private Properties

    private var utxo: [AlephiumUTXO] = []

    // MARK: - Public Implementation

    func update(utxo: [AlephiumUTXO]) {
        self.utxo = utxo
    }

    // MARK: - Private Implementation
}
