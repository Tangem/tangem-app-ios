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

    init() {
        blockchainViewModels = SupportedBlockchains.testable
            .map { blockchain in
                DefaultToggleRowViewModel(
                    title: blockchain.displayName,
                    isOn: .init(get: {
                        return FeatureStorage().supportedBlockchainsIds.contains(blockchain.id)
                    }, set: { newValue in
                        if newValue {
                            FeatureStorage().supportedBlockchainsIds.append(blockchain.id)
                        } else {
                            FeatureStorage().supportedBlockchainsIds.removeAll(where: { $0 == blockchain.id })
                        }
                    })
                )
            }
    }
}
