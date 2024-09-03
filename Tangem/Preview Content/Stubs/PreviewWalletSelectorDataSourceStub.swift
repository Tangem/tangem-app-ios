//
//  PreviewWalletSelectorDataSourceStub.swift
//  Tangem
//
//  Created by skibinalexander on 17.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class PreviewWalletSelectorDataSourceStub: WalletSelectorDataSource {
    private var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var itemViewModels: [WalletSelectorItemViewModel] = []

    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }
}

class PreviewMarketsWalletSelectorDataSourceStub: WalletSelectorDataSource {
    private var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var itemViewModels: [WalletSelectorItemViewModel] = []

    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }
}
