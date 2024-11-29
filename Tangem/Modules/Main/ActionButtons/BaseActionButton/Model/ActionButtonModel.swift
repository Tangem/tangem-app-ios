//
//  ActionButtonModel.swift
//  Tangem
//
//  Created by GuitarKitty on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum ActionButtonModel: Hashable {
    case buy
    case swap
    case sell

    var title: String {
        switch self {
        case .buy:
            Localization.commonBuy
        case .swap:
            Localization.commonSwap
        case .sell:
            Localization.commonSell
        }
    }

    var icon: ImageType {
        switch self {
        case .buy:
            Assets.plusMini
        case .swap:
            Assets.exchangeMini
        case .sell:
            Assets.dollarMini
        }
    }
}

enum ActionButtonState: Equatable {
    case initial
    case loading
    case idle
    case disabled(message: String)
}
