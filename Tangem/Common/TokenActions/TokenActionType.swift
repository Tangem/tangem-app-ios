//
//  TokenActionType.swift
//  Tangem
//
//  Created by Andrew Son on 15/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TokenActionType {
    case buy
    case send
    case receive
    case exchange
    case sell
    case copyAddress
    case hide

    var title: String {
        switch self {
        case .buy: return Localization.commonBuy
        case .send: return Localization.commonSend
        case .receive: return Localization.commonReceive
        case .exchange: return Localization.commonExchange
        case .sell: return Localization.commonSell
        case .copyAddress: return Localization.commonCopyAddress
        case .hide: return Localization.tokenDetailsHideToken
        }
    }

    var icon: ImageType {
        switch self {
        case .buy: return Assets.plusMini
        case .send: return Assets.arrowUpMini
        case .receive: return Assets.arrowDownMini
        case .exchange: return Assets.exchangeMini
        case .sell: return Assets.dollarMini
        case .copyAddress: return Assets.copy
        case .hide: return Assets.minusCircle
        }
    }

    var isDestructive: Bool {
        switch self {
        case .hide: return true
        default: return false
        }
    }
}
