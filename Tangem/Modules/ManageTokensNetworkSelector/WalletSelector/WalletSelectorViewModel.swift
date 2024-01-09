//
//  WalletSelectorViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletSelectorViewModel: ObservableObject {
    var itemViewModels: [WalletSelectorItemViewModel] = []

    private weak var dataSource: WalletSelectorDataSource?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(dataSource: WalletSelectorDataSource?) {
        self.dataSource = dataSource
        itemViewModels = dataSource?.itemViewModels ?? []

        bind()
    }

    private func bind() {
        dataSource?.selectedUserWalletModelPublisher
            .sink { [weak self] userWalletId in
                self?.itemViewModels.forEach { item in
                    item.isSelected = item.userWalletId == userWalletId
                }
            }
            .store(in: &bag)
    }
}
