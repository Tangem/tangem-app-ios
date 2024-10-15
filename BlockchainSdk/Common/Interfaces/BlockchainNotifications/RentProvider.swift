//
//  RentProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.02.2024.
//

import Foundation
import Combine

public protocol RentProvider {
    func minimalBalanceForRentExemption() -> AnyPublisher<Amount, Error>
    func rentAmount() -> AnyPublisher<Amount, Error>
}
