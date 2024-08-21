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
    @Published var blockchainViewModels: [DefaultToggleRowViewModel] = []
    private let featureStorage = FeatureStorage()

    init(
        blockchainIds: Set<String>,
        featureStorageKeyPath: ReferenceWritableKeyPath<FeatureStorage, [String]>
    ) {
        blockchainViewModels = blockchainIds
            .map { coinId in
                DefaultToggleRowViewModel(
                    title: coinId.capitalizingFirstLetter(),
                    isOn: .init(
                        root: self,
                        default: false,
                        get: { root in
                            return root.featureStorage[keyPath: featureStorageKeyPath].contains(coinId)
                        }, set: { root, newValue in
                            if newValue {
                                root.featureStorage[keyPath: featureStorageKeyPath].append(coinId)
                            } else {
                                root.featureStorage[keyPath: featureStorageKeyPath].removeAll(where: { $0 == coinId })
                            }
                        }
                    )
                )
            }
    }
}
