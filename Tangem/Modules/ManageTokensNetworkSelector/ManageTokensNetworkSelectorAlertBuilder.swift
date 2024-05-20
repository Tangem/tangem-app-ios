//
//  ManageTokensNetworkSelectorAlertBuilder.swift
//  Tangem
//
//  Created by skibinalexander on 25.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensNetworkSelectorAlertBuilder {
    func successCanRemoveAlertDeleteTokenIfNeeded(
        tokenItem: TokenItem,
        cancelAction: @escaping () -> Void,
        hideAction: @escaping () -> Void
    ) -> AlertBinder {
        let title = Localization.tokenDetailsHideAlertTitle(tokenItem.currencySymbol)

        return AlertBinder(alert:
            Alert(
                title: Text(title),
                message: Text(Localization.tokenDetailsHideAlertMessage),
                primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: hideAction),
                secondaryButton: .cancel(cancelAction)
            )
        )
    }

    func errorCanRemoveAlertDeleteTokenIfNeeded(
        tokenItem: TokenItem,
        dissmisAction: @escaping (TokenItem) -> Void
    ) -> AlertBinder {
        let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.blockchain.currencySymbol)

        let message = Localization.tokenDetailsUnableHideAlertMessage(
            tokenItem.name,
            tokenItem.blockchain.currencySymbol,
            tokenItem.blockchain.displayName
        )

        return AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text(Localization.commonOk), action: {
                dissmisAction(tokenItem)
            })
        ))
    }
}
