//
//  MarketsTokensNetworkDataSource.swift
//  Tangem
//
//  Created by skibinalexander on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsWalletDataSource {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Properties

    private let _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])
    private let _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var userWalletModels: [UserWalletModel] { _userWalletModels.value }
    var selectedUserWalletModel: UserWalletModel? { _selectedUserWalletModel.value }

    // MARK: - Init

    init() {
        let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked && $0.config.hasFeature(.multiCurrency) }

        _userWalletModels.send(userWalletModels)

        let selectedUserWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == userWalletRepository.selectedUserWalletId
        } ?? userWalletModels.first

        _selectedUserWalletModel.send(selectedUserWalletModel)
    }
}

extension MarketsWalletDataSource: MarketsWalletSelectorProvider {
    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

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
