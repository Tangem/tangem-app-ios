//
//  BlockBookResponse+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 29.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Convenience extensions

extension BlockBookAddressResponse.Transaction {
    var compat: BlockBookAddressResponse.Compat<Self> { .init(wrapped: self) }
}

extension BlockBookAddressResponse.TokenTransfer {
    var compat: BlockBookAddressResponse.Compat<Self> { .init(wrapped: self) }
}

extension BlockBookAddressResponse.Compat where T == BlockBookAddressResponse.Transaction {
    /// Has a value only for UTXO and Ethereum-like blockchains.
    var vin: [BlockBookAddressResponse.Vin] { wrapped.vin ?? [] }
    /// Has a value only for UTXO and Ethereum-like blockchains.
    var vout: [BlockBookAddressResponse.Vout] { wrapped.vout ?? [] }
}

extension BlockBookAddressResponse.Compat where T == BlockBookAddressResponse.TokenTransfer {
    /// For some blockchains (e.g. Ethereum POW) the contract address is stored
    /// in the `token` field instead of the `contract` field of the response.
    var contract: String? { wrapped.contract ?? wrapped.token }
}

// MARK: - Auxiliary types

extension BlockBookAddressResponse {
    /// Helper DTO type to provide better compatibility for slightly different Blockbook responses for different blockchains.
    struct Compat<T> {
        let wrapped: T
    }
}
