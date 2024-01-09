//
//  ManageTokensNetworkDataSource.swift
//  Tangem
//
//  Created by skibinalexander on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensNetworkDataSource {
    // MARK: - Properties

    private let _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])
    private let _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var userWalletModels: [UserWalletModel] { _userWalletModels.value }
    var selectedUserWalletModel: UserWalletModel? { _selectedUserWalletModel.value }

    // MARK: - Init

    init(_ dataSource: ManageTokensDataSource) {
        let userWalletModels = dataSource.userWalletModels.filter { $0.isMultiWallet }

        _userWalletModels.send(userWalletModels)

        let selectedUserWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == dataSource.defaultUserWalletModel?.userWalletId
        } ?? userWalletModels.first

        _selectedUserWalletModel.send(selectedUserWalletModel)
    }
}

extension ManageTokensNetworkDataSource: WalletSelectorDataSource {
    var selectedUserWalletModelPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

    var itemViewModels: [WalletSelectorItemViewModel] {
        userWalletModels.map { userWalletModel in
            WalletSelectorItemViewModel(
                userWalletId: userWalletModel.userWalletId,
                name: userWalletModel.config.cardName,
                cardImagePublisher: userWalletModel.cardImagePublisher,
                isSelected: userWalletModel.userWalletId == _selectedUserWalletModel.value?.userWalletId
            ) { [weak self] userWalletId in
                guard let self = self else { return }

                let selectedUserWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId })
                _selectedUserWalletModel.send(selectedUserWalletModel)
            }
        }
    }
}
