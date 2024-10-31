//
//  EthereumAddressConverter.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol EthereumAddressConverter {
    func convertToETHAddress(_ address: String) throws -> String
}

extension EthereumAddressConverter {
    func convertToETHAddressPublisher(_ address: String) -> AnyPublisher<String, Error> {
        return Result { try convertToETHAddress(address) }
            .publisher
            .eraseToAnyPublisher()
    }

    func convertToETHAddresses(in transaction: Transaction) throws -> Transaction {
        var tx = transaction
        tx.sourceAddress = try convertToETHAddress(tx.sourceAddress)
        tx.destinationAddress = try convertToETHAddress(tx.destinationAddress)
        tx.changeAddress = try convertToETHAddress(tx.changeAddress)
        tx.contractAddress = try tx.contractAddress.map { try convertToETHAddress($0) }
        return tx
    }

    func convertToETHAddressesPublisher(in transaction: Transaction) -> AnyPublisher<Transaction, Error> {
        return Result { try convertToETHAddresses(in: transaction) }
            .publisher
            .eraseToAnyPublisher()
    }
}
