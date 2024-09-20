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

    var selectedUserWalletModel: UserWalletModel? { _selectedUserWalletModel.value }

    var isWalletSelectorAvailable: Bool {
        userWalletRepository.models.filter { !$0.isUserWalletLocked && $0.config.hasFeature(.multiCurrency) }.count > 1
    }

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        setupUserWalletModels()
        bind()
    }

    private func setupUserWalletModels() {
        let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        _userWalletModels.send(userWalletModels)

        if _selectedUserWalletModel.value == nil {
            let multiCurrencyWallets = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }
            let selectedUserWalletModel = multiCurrencyWallets
                .first { userWalletModel in
                    userWalletModel.userWalletId == userWalletRepository.selectedUserWalletId
                } ?? multiCurrencyWallets.first

            _selectedUserWalletModel.send(selectedUserWalletModel)
        }
    }

    private func clearUserWalletModels() {
        _userWalletModels.send([])
        _selectedUserWalletModel.send(nil)
    }

    private func bind() {
        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink(receiveValue: { dataProvider, event in
                switch event {
                case .locked:
                    dataProvider.clearUserWalletModels()
                case .inserted, .updated, .biometryUnlocked, .scan:
                    dataProvider.setupUserWalletModels()
                case .deleted(let userWalletIds):
                    if let selectedUserWalletModel = dataProvider.selectedUserWalletModel, userWalletIds.contains(where: { $0 == selectedUserWalletModel.userWalletId }) {
                        dataProvider._selectedUserWalletModel.send(nil)
                    }
                    dataProvider.setupUserWalletModels()
                case .selected(let userWalletId, _):
                    if let selectedUserWalletModel = dataProvider.selectedUserWalletModel, selectedUserWalletModel.userWalletId == userWalletId {
                        return
                    }

                    guard
                        let selectedUserWalletModel = dataProvider.userWalletRepository.selectedModel,
                        selectedUserWalletModel.config.hasFeature(.multiCurrency)
                    else {
                        return
                    }

                    dataProvider._selectedUserWalletModel.send(selectedUserWalletModel)
                case .replaced:
                    dataProvider._selectedUserWalletModel.send(nil)
                    dataProvider.setupUserWalletModels()
                }
            })
            .store(in: &bag)
    }
}

extension MarketsWalletDataProvider {
    var userWalletModels: [UserWalletModel] { _userWalletModels.value }

    var userWalletModelsPublisher: AnyPublisher<[UserWalletModel], Never> {
        _userWalletModels.eraseToAnyPublisher()
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
