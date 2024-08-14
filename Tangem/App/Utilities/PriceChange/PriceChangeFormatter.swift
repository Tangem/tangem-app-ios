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

    func formatPercentValue(_ value: Decimal, option: PercentFormatter.Option) -> PriceChangeFormatter.Result {
        // We need to multiply to 0.01 because percent formatter uses NumberFormatter with percent style
        let valueToFormat = value * 0.01
        return format(valueToFormat, option: option)
    }

    func formatFractionalValue(_ value: Decimal, option: PercentFormatter.Option) -> PriceChangeFormatter.Result {
        return format(value, option: option)
    }

    private func format(_ value: Decimal, option: PercentFormatter.Option) -> PriceChangeFormatter.Result {
        let scale = option.fractionDigits + 2 // multiplication by 100 for percents
        let roundedValue = value.rounded(scale: scale, roundingMode: .plain)
        let formattedText = percentFormatter.format(roundedValue, option: option)
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
