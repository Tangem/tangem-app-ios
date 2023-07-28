//
//  CardViewModel+Mock.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CardViewModel {
    static let mock = CardViewModel(
        cardInfo: CardInfo(card: .init(card: .walletWithBackup), walletData: .none, name: "", artwork: .noArtwork, primaryCard: nil)
    )
}
