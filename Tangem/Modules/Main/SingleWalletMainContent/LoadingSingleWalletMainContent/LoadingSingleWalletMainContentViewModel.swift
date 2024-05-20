//
//  LoadingSingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 08/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct LoadingSingleWalletMainContentViewModel {
    let buttonsInfo: [FixedSizeButtonWithIconInfo] = TokenActionListBuilder()
        .buildActionsForLockedSingleWallet()
        .map {
            FixedSizeButtonWithIconInfo(
                title: $0.title,
                icon: $0.icon,
                disabled: true,
                style: .disabled,
                action: {}
            )
        }
}
