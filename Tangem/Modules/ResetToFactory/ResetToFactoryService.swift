//
//  ResetToFactoryService.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class ResetToFactoryService {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var hasCardsToReset: Bool { totalCardsCount != resettedCardsCount }
    var cardNumberToReset: Int { min(resettedCardsCount + 1, totalCardsCount) }

    private(set) var resettedCardsCount: Int = 0

    private let userWalletId: UserWalletId
    private let totalCardsCount: Int

    init(userWalletId: UserWalletId, totalCardsCount: Int) {
        self.totalCardsCount = totalCardsCount
        self.userWalletId = userWalletId
    }

    func cardDidReset() {
        resettedCardsCount += 1
    }

    func resetDidDinish() {
        logAnalytics()
        userWalletRepository.delete(userWalletId)
    }

    private func logAnalytics() {
        let params = [Analytics.ParameterKey.cardsCount: "\(resettedCardsCount)"]

        if hasCardsToReset {
            Analytics.log(event: .factoryResetCancelled, params: params)
        } else {
            Analytics.log(event: .factoryResetFinished, params: params)
        }
    }
}
