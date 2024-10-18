//
//  TokenItemMenuActions.swift
//  Tangem
//
//  Created by skibinalexander on 14.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

public struct TokenItemMenuActions: View {
    // MARK: - Properties

    let actions: [Action]
    let didTapAction: (Action) -> Void

    // MARK: - Setup UI

    public var body: some View {
        ForEach(actions, id: \.hashValue) { action in
            Button {
                didTapAction(action)
            } label: {
                HStack {
                    Text(action.title)

                    action.icon.image
                }
            }
        }
    }
}

// MARK: - Action Type

public extension TokenItemMenuActions {
    enum Action {
        case copyAddress
        case receive
        case sell
        case buy
        case send
        case exchange

        var title: String {
            switch self {
            case .copyAddress:
                return Localization.commonCopyAddress
            case .receive:
                return Localization.commonReceive
            case .sell:
                return Localization.commonSell
            case .buy:
                return Localization.commonBuy
            case .send:
                return Localization.commonSend
            case .exchange:
                return Localization.swappingSwapAction
            }
        }

        var icon: ImageType {
            switch self {
            case .copyAddress:
                return Assets.TokenItemContextMenu.menuCopy
            case .receive:
                return Assets.TokenItemContextMenu.menuArrowDownMini
            case .sell:
                return Assets.TokenItemContextMenu.menuArrowRightUpMini
            case .buy:
                return Assets.TokenItemContextMenu.menuPlusMini
            case .send:
                return Assets.TokenItemContextMenu.menuArrowUpMini
            case .exchange:
                return Assets.TokenItemContextMenu.menuExchangeMini
            }
        }
    }
}
