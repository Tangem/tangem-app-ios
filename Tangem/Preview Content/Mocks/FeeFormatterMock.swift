//
//  FeeFormatterMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

struct FeeFormatterMock: FeeFormatter {
    func formattedFeeComponents(
        fee: Decimal,
        currencySymbol: String,
        currencyId: String?,
        isFeeApproximate: Bool,
        formattingOptions: BalanceFormattingOptions
    ) -> FormattedFeeComponents {
        FormattedFeeComponents(cryptoFee: "", fiatFee: nil)
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String { "" }
}
