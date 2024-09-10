//
//  TokenActionType.swift
//  Tangem
//
//  Created by Andrew Son on 15/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TokenActionType: String {
    case buy
    case send
    case receive
    case exchange
    case stake
    case sell
    case copyAddress
    case marketsDetails
    case hide

    var title: String {
        switch self {
        case .buy: return Localization.commonBuy
        case .send: return Localization.commonSend
        case .receive: return Localization.commonReceive
        case .exchange: return Localization.swappingSwapAction
        case .stake: return Localization.commonStake
        case .sell: return Localization.commonSell
        case .copyAddress: return Localization.commonCopyAddress
        case .marketsDetails: return Localization.commonAnalytics
        case .hide: return Localization.tokenDetailsHideToken
        }
    }

    var icon: ImageType {
        switch self {
        case .buy: return Assets.plusMini
        case .send: return Assets.arrowUpMini
        case .receive: return Assets.arrowDownMini
        case .exchange: return Assets.exchangeMini
        case .stake: return Assets.stakingIcon
        case .sell: return Assets.dollarMini
        case .copyAddress: return Assets.copy
        case .marketsDetails: return Assets.chartMini20
        case .hide: return Assets.minusCircle
        }
    }

    var isDestructive: Bool {
        switch self {
        case .hide: return true
        default: return false
        }
    }

    var description: String? {
        switch self {
        case .buy: return Localization.buyTokenDescription
        case .send: return nil
        case .receive: return Localization.receiveTokenDescription
        case .exchange: return Localization.exсhangeTokenDescription
        case .stake: return nil
        case .sell: return nil
        case .copyAddress: return nil
        case .marketsDetails: return nil
        case .hide: return nil
        }
    }

    var analyticsParameterValue: String {
        rawValue.capitalizingFirstLetter()
    }
}

extension TokenActionType: CaseIterable, Identifiable {
    var id: String { rawValue }
}
