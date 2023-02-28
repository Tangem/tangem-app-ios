//
//  ExchangeButtonStateType.swift
//  Tangem
//
//  Created by Skibin Alexander on 21.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Type of main button view
enum ExchangeButtonType: Hashable, CaseIterable {
    case buy
    case sell
    case swap

    var title: String {
        switch self {
        case .buy:
            return Localization.walletButtonBuy
        case .sell:
            return Localization.walletButtonSell
        case .swap:
            return Localization.swappingSwapAction
        }
    }

    var icon: ImageType {
        switch self {
        case .buy:
            return Assets.arrowUpMini
        case .sell:
            return Assets.arrowDownMini
        case .swap:
            return Assets.exchangeIcon
        }
    }

    // MARK: - Helper

    static func build(
        canBuyCrypto: Bool,
        canSellCrypto: Bool,
        canSwap: Bool = false
    ) -> [ExchangeButtonType] {
        var exchangeOptions = ExchangeButtonType.allCases.filter { option in
            switch option {
            case .buy:
                return canBuyCrypto
            case .sell:
                return canSellCrypto
            case .swap:
                return canSwap
            }
        }

        // If options is empty, we must display buy button where button is disabled
        if exchangeOptions.isEmpty {
            exchangeOptions.append(.buy)
        }

        return exchangeOptions
    }
}

/// State of main button view
enum ExchangeButtonState: Hashable {
    case single(option: ExchangeButtonType)
    case multi(options: [ExchangeButtonType])

    var options: [ExchangeButtonType] {
        switch self {
        case .single(let option):
            return [option]
        case .multi(let options):
            return options
        }
    }

    init(options: [ExchangeButtonType]) {
        if options.count == 1, let option = options.first {
            self = .single(option: option)
        } else {
            self = .multi(options: options)
        }
    }
}
