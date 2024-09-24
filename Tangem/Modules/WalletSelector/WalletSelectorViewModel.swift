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
    private weak var coordinator: WalletSelectorRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(dataSource: WalletSelectorDataSource?, coordinator: WalletSelectorRoutable? = nil) {
        self.dataSource = dataSource
        self.coordinator = coordinator

        itemViewModels = dataSource?.itemViewModels ?? []

        bind()
    }

    private func bind() {
        dataSource?.selectedUserWalletIdPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userWalletId in
                self?.itemViewModels.forEach { item in
                    item.isSelected = item.userWalletId == userWalletId
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.coordinator?.dissmisWalletSelectorModule()
                }
            }
            .store(in: &bag)
    }
}
