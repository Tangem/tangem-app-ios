//
//  PriceChangeFormatter.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PriceChangeFormatter {
    private let percentFormatter: PercentFormatter

    init(percentFormatter: PercentFormatter = .init()) {
        self.percentFormatter = percentFormatter
    }

    func format(value: Decimal) -> PriceChangeFormatter.Result {
        let roundedValue = value.rounded(scale: PercentFormatter.Constants.maximumFractionDigits, roundingMode: .plain)
        let formattedText = percentFormatter.percentFormat(value: roundedValue)
        let signType = ChangeSignType(from: roundedValue)
        return Result(formattedText: formattedText, signType: signType)
    }

    func formatExpress(value: Decimal) -> PriceChangeFormatter.Result {
        let scale = PercentFormatter.Constants.maximumFractionDigitsExpress + 2 // multiplication by 100 for percents
        let roundedValue = value.rounded(scale: scale, roundingMode: .plain)
        let formattedText = percentFormatter.expressRatePercentFormat(value: roundedValue)
        let signType = ChangeSignType(from: roundedValue)
        return Result(formattedText: formattedText, signType: signType)
    }
}

extension PriceChangeFormatter {
    struct Result {
        let formattedText: String
        let signType: ChangeSignType
    }
}
