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
    private let featureStorage = FeatureStorage()

    init() {
        blockchainViewModels = SupportedBlockchains.testableIDs
            .map { coinId in
                DefaultToggleRowViewModel(
                    title: coinId.capitalizingFirstLetter(),
                    isOn: .init(
                        root: self,
                        default: false,
                        get: { root in
                            return root.featureStorage.supportedBlockchainsIds.contains(coinId)
                        }, set: { root, newValue in
                            if newValue {
                                root.featureStorage.supportedBlockchainsIds.append(coinId)
                            } else {
                                root.featureStorage.supportedBlockchainsIds.removeAll(where: { $0 == coinId })
                            }
                        }
                    )
                )
            }
    }
}
