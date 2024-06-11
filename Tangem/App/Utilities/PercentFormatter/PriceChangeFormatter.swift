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

    func format(_ value: Decimal, option: PercentFormatter.Option) -> PriceChangeFormatter.Result {
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
