//
//  MarketsTokensNetworkDataSource.swift
//  Tangem
//
//  Created by skibinalexander on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsWalletDataProvider {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Properties

    private let _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])
    private let _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var userWalletModels: [UserWalletModel] { _userWalletModels.value }
    var selectedUserWalletModel: UserWalletModel? { _selectedUserWalletModel.value }

    var isAvaialableWalletSelector: Bool {
        userWalletModels.filter { !$0.isUserWalletLocked && $0.config.hasFeature(.multiCurrency) }.count > 1
    }

    // MARK: - Init

    init() {
        let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        _userWalletModels.send(userWalletModels)

        let selectedUserWalletModel = userWalletModels.first { userWalletModel in
            userWalletModel.userWalletId == userWalletRepository.selectedUserWalletId
        } ?? userWalletModels.first

        _selectedUserWalletModel.send(selectedUserWalletModel)
    }
}

extension MarketsWalletDataProvider: WalletSelectorDataSource {
    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

    var selectedUserWalletModelPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

    var itemViewModels: [WalletSelectorItemViewModel] {
        userWalletModels
            .filter { $0.config.hasFeature(.multiCurrency) }
            .map { userWalletModel in
                WalletSelectorItemViewModel(
                    userWalletId: userWalletModel.userWalletId,
                    cardsCount: userWalletModel.cardsCount,
                    isUserWalletLocked: userWalletModel.isUserWalletLocked,
                    userWalletNamePublisher: userWalletModel.userWalletNamePublisher,
                    totalBalancePublisher: userWalletModel.totalBalancePublisher,
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
