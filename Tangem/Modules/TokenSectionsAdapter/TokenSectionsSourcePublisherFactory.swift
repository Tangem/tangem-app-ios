//
//  TokenSectionsSourcePublisherFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 04.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

/// A factory that creates a so-called `source publisher` for use with `TokenSectionsAdapter.organizedSections(from:on:)`
/// method as the source of truth for creating token sections.
struct TokenSectionsSourcePublisherFactory {
    func makeSourcePublisher(for userWalletModel: UserWalletModel) -> some Publisher<[WalletModel], Never> {
        // The contents of the coins and tokens collection for the user wallet
        let walletModelsPublisher = userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
            .eraseToAnyPublisher()

        // Fiat balance changes for the coins and tokens for the user wallet
        let walletModelsBalanceChangesPublisher = userWalletModel
            .totalBalancePublisher
            .filter { !$0.isLoading }
            .withLatestFrom(walletModelsPublisher)
            .eraseToAnyPublisher()

        return [
            walletModelsPublisher,
            walletModelsBalanceChangesPublisher,
        ].merge()
    }

    func makeLightSourcePublisher(for userWalletModel: UserWalletModel) -> some Publisher<[WalletModel], Never> {
        // The contents of the coins and tokens collection for the user wallet
        return userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
            .eraseToAnyPublisher()
    }
}
