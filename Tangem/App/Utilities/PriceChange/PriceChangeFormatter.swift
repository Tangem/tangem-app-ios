//
//  PriceChangeFormatter.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PriceChangeFormatter {
    private let percentFormatter: PercentFormatter

    init(percentFormatter: PercentFormatter = .init()) {
        self.percentFormatter = percentFormatter
    }

    /// Use this function when you have a percent value and you want to convert it to a string.
    /// E.g. `0.01` will be converted into `0.01%`
    /// `10` -> `10%`
    /// `100` -> `100%`
    func formatPercentValue(_ value: Decimal, option: PercentFormatter.Option) -> PriceChangeFormatter.Result {
        // We need to multiply to 0.01 because percent formatter uses NumberFormatter with percent style
        let valueToFormat = value * 0.01
        return format(valueToFormat, option: option)
    }

    /// Use this function when you have fractional representation of a value and you want to convert it to a string.
    /// E.g. `0.01` will be converted into `1%`
    /// `0.001` -> `0.1%`
    /// `1` -> `100%`
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
