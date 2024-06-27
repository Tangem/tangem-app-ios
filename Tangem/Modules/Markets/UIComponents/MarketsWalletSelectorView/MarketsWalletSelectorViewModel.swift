//
//  MarketsWalletSelectorViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsWalletSelectorViewModel: ObservableObject {
    var itemViewModels: [WalletSelectorItemViewModel] = []

    private weak var provider: MarketsWalletSelectorProvider?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(provider: MarketsWalletSelectorProvider?) {
        self.provider = provider
        itemViewModels = provider?.itemViewModels ?? []

        bind()
    }

    private func bind() {
        provider?.selectedUserWalletIdPublisher
            .sink { [weak self] userWalletId in
                self?.itemViewModels.forEach { item in
                    item.isSelected = item.userWalletId == userWalletId
                }
            }
            .store(in: &bag)
    }
}
