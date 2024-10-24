//
//  ActionButton.swift
//  Tangem
//
//  Created by GuitarKitty on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum ActionButtonPresentationState: Equatable {
    case unexplicitLoading
    case loading
    case idle
}

enum ActionButton: Hashable {
    case buy
    case swap
    case sell

    var title: String {
        switch self {
        case .buy:
            "Buy"
        case .swap:
            "Swap"
        case .sell:
            "Sell"
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
