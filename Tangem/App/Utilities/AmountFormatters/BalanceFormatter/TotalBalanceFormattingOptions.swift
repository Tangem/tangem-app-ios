//
//  TotalBalanceFormattingOptions.swift
//  Tangem
//
//  Created by Andrew Son on 11/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TotalBalanceFormattingOptions {
    let integerPartFont: Font
    let fractionalPartFont: Font
    let integerPartColor: Color
    let fractionalPartColor: Color

    static var defaultOptions: TotalBalanceFormattingOptions {
        .init(
            integerPartFont: Fonts.Regular.title1,
            fractionalPartFont: Fonts.Bold.title3,
            integerPartColor: Colors.Text.primary1,
            fractionalPartColor: Colors.Text.primary1
        )
    }
}
