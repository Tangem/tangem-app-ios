//
//  SupportedBlockchainsPreferencesViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class SupportedBlockchainsPreferencesViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var blockchainViewModels: [DefaultToggleRowViewModel] = []

    init() {
        blockchainViewModels = SupportedBlockchains.testableIDs
            .map { coinId in
                DefaultToggleRowViewModel(
                    title: coinId.capitalizingFirstLetter(),
                    isOn: .init(get: {
                        return FeatureStorage().supportedBlockchainsIds.contains(coinId)
                    }, set: { newValue in
                        if newValue {
                            FeatureStorage().supportedBlockchainsIds.append(coinId)
                        } else {
                            FeatureStorage().supportedBlockchainsIds.removeAll(where: { $0 == coinId })
                        }
                    })
                )
            }
    }
}
