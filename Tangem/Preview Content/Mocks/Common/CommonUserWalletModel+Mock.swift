//
//  CommonUserWalletModel+Mock.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CommonUserWalletModel {
    static let mock = CommonUserWalletModelFactory().makeModel(
        cardInfo: CardMock.wallet.cardInfo
    )

    static let visaMock = CommonUserWalletModelFactory().makeModel(
        cardInfo: CardMock.visa.cardInfo
    )
}
