//
//  TransactionFeeProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol TransactionFeeProvider {
    var allowsFeeSelection: Bool { get }

    /// Use this method only for get a estimation fee
    /// Better use `getFee(amount:destination:)` for calculate the right fee for transaction
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error>
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
}

public extension TransactionFeeProvider where Self: WalletProvider {
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        do {
            let estimationFeeAddress = try EstimationFeeAddressFactory().makeAddress(for: wallet.blockchain)
            return getFee(amount: amount, destination: estimationFeeAddress)
        } catch {
            return .anyFail(error: error)
        }
    }
}
