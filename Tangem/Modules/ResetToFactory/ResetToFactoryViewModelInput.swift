//
//  ResetToFactoryViewModelInput.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension ResetToFactoryViewModel {
    struct Input {
        let cardInteractor: FactorySettingsResetting
        let backupCardsCount: Int
        let userWalletId: UserWalletId
    }
}
