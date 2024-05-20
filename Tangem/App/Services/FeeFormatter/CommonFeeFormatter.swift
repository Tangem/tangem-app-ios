//
//  CommonFeeFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct CommonFeeFormatter {
    private let balanceFormatter: BalanceFormatter
    private let balanceConverter: BalanceConverter

    init(
        balanceFormatter: BalanceFormatter,
        balanceConverter: BalanceConverter
    ) {
        self.balanceFormatter = balanceFormatter
        self.balanceConverter = balanceConverter
    }
}

// MARK: - FeeFormatter

extension CommonFeeFormatter: FeeFormatter {
    func formattedFeeComponents(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> FormattedFeeComponents {
        let cryptoFeeFormatted = balanceFormatter.formatCryptoBalance(fee, currencyCode: currencySymbol)
        let fiatFeeFormatted: String?

        if let currencyId, let fiatFee = balanceConverter.convertToFiat(value: fee, from: currencyId) {
            fiatFeeFormatted = fiatFeeFormatter(fee: fiatFee)
        } else {
            fiatFeeFormatted = nil
        }

        let useApproximationSymbol = fee > 0 && isFeeApproximate

        return FormattedFeeComponents(
            cryptoFee: useApproximationSymbol ? ("< " + cryptoFeeFormatted) : cryptoFeeFormatted,
            fiatFee: fiatFeeFormatted
        )
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String {
        let formattedFee: FormattedFeeComponents = formattedFeeComponents(
            fee: fee,
            currencySymbol: currencySymbol,
            currencyId: currencyId,
            isFeeApproximate: isFeeApproximate
        )

        if let fiatFee = formattedFee.fiatFee {
            return "\(formattedFee.cryptoFee) (\(fiatFee))"
        } else {
            return formattedFee.cryptoFee
        }
    }

    // MARK: - Private Implementation

    private func fiatFeeFormatter(fee value: Decimal) -> String {
        if value > Constants.feeLowBoundaryDecimalValue {
            return balanceFormatter.formatFiatBalance(value)
        } else {
            return Constants.fiatFeeLowBoundaryStringValue
        }
    }
}

extension CommonFeeFormatter {
    enum Constants {
        static let feeLowBoundaryDecimalValue: Decimal = 0.01
        static let fiatFeeLowBoundaryStringValue = "<0.01"
    }
}
