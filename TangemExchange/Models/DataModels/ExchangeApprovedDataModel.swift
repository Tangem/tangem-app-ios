//
//  ExchangeApprovedDataModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 08.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeApprovedDataModel {
    public let data: Data
    public let tokenAddress: String

    /// The value which send for approve in WEI
    public let value: Decimal

    public init(approveTxData: ApprovedTransactionData) throws {
        guard let value = Decimal(string: approveTxData.value) else {
            throw OneInchExchangeProvider.Errors.incorrectDataFormat
        }

        self.value = value

        data = Data(hexString: approveTxData.data)
        tokenAddress = approveTxData.to
    }
}
