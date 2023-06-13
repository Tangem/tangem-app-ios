//
//  SwappingAvailabilityModel.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 18.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingAvailabilityModel {
    public let transactionData: SwappingTransactionData
    public let gasOptions: [EthereumGasDataModel]
    public let restrictions: Restrictions

    public var destinationAmount: Decimal {
        transactionData.destinationCurrency.convertFromWEI(
            value: transactionData.destinationAmount
        )
    }

    public func isEnoughAmountForSwapping(for policy: SwappingGasPricePolicy) -> Bool {
        restrictions.isEnoughAmountForSwapping[policy] ?? false
    }

    public func isEnoughAmountForFee(for policy: SwappingGasPricePolicy) -> Bool {
        restrictions.isEnoughAmountForFee[policy] ?? false
    }

    public init(
        transactionData: SwappingTransactionData,
        gasOptions: [EthereumGasDataModel],
        restrictions: Restrictions
    ) {
        self.transactionData = transactionData
        self.gasOptions = gasOptions
        self.restrictions = restrictions
    }
}

public extension SwappingAvailabilityModel {
    struct Restrictions {
        public let isEnoughAmountForSwapping: [SwappingGasPricePolicy: Bool]
        public let isEnoughAmountForFee: [SwappingGasPricePolicy: Bool]
        public let isPermissionRequired: Bool

        public init(
            isEnoughAmountForSwapping: [SwappingGasPricePolicy: Bool],
            isEnoughAmountForFee: [SwappingGasPricePolicy: Bool],
            isPermissionRequired: Bool
        ) {
            self.isEnoughAmountForSwapping = isEnoughAmountForSwapping
            self.isEnoughAmountForFee = isEnoughAmountForFee
            self.isPermissionRequired = isPermissionRequired
        }
    }
}
