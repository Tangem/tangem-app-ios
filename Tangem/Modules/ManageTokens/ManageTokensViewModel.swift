//
//  ManageTokensViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class ManageTokensViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var alert: AlertBinder?
    @Published var tokenViewModels: [ManageTokensItemViewModel] = []
    @Published var isLoading: Bool = true
    @Published var generateAddressesViewModel: GenerateAddressesViewModel?

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private unowned let coordinator: ManageTokensRoutable

    private lazy var loader = setupListDataLoader()

    private var bag = Set<AnyCancellable>()
    private var cacheExistListCoinId: [String] = []
    private var pendingDerivationCountByWalletId: [UserWalletId: Int] = [:]

    init(coordinator: ManageTokensRoutable, enteredSearchText: String = "") {
        self.coordinator = coordinator

        loader.reset(enteredSearchText)

        bind()
        updateAlreadyExistTokenUserList()
    }

    func onAppear(with searchText: String = "") {
        Analytics.log(.manageTokensScreenOpened)
        loader.reset(searchText)
        loader.fetch(searchText)
    }

    func fetch(searchText: String) {
        loader.fetch(searchText)
    }
}

// MARK: - Private Implementation

private extension ManageTokensViewModel {
    /// Obtain supported token list from UserWalletModels to determine the cell action type
    /// Should be reset after updating the list of tokens
    func updateAlreadyExistTokenUserList() {
        let existEntriesList = userWalletRepository.models
            .map { $0.userTokenListManager }
            .flatMap { userTokenListManager in
                let entries = userTokenListManager.userTokensList.entries
                return entries.compactMap { $0.isCustom ? nil : $0.id }
            }

        cacheExistListCoinId = existEntriesList
    }

    func bind() {
        // Need for update state generateAddressesViewModel property
        let pendingDerivationsCountPublishers = userWalletRepository.models
            .compactMap { model -> AnyPublisher<(UserWalletId, Int), Never>? in
                if let derivationManager = model.userTokensManager.derivationManager {
                    return derivationManager.pendingDerivationsCount
                        .map { (model.userWalletId, $0) }
                        .eraseToAnyPublisher()
                }

                return nil
            }

        Publishers.MergeMany(pendingDerivationsCountPublishers)
            .receiveValue { [weak self] id, count in
                self?.pendingDerivationCountByWalletId[id] = count
                self?.updateGenerateAddressesViewModel()
            }
            .store(in: &bag)

        // Used for update state actionType tokenViewModels list property
        let userTokensPublishers = userWalletRepository.models
            .map { $0.userTokenListManager.userTokensPublisher }

        Publishers.MergeMany(userTokensPublishers)
            .receiveValue { [weak self] value in
                guard let self = self else { return }

                updateAlreadyExistTokenUserList()

                tokenViewModels.forEach {
                    $0.action = self.actionType(for: $0.id)
                }
            }
            .store(in: &bag)
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self = self else {
                    return
                }

                tokenViewModels = items.compactMap { self.mapToTokenViewModel(coinModel: $0) }
                updateQuote(by: items.map { $0.id })
            })
            .store(in: &bag)

        return loader
    }

    // MARK: - Private Implementation

    private func actionType(for coinId: String) -> ManageTokensItemViewModel.Action {
        let isAlreadyExistToken = cacheExistListCoinId.contains(coinId)
        return isAlreadyExistToken ? .edit : .add
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel {
        ManageTokensItemViewModel(
            coinModel: coinModel,
            action: actionType(for: coinModel.id),
            didTapAction: handle(action:with:)
        )
    }

    private func updateQuote(by coinIds: [String]) {
        runTask(in: self) { root in
            await root.tokenQuotesRepository.loadQuotes(currencyIds: coinIds)
        }
    }

    private func handle(action: ManageTokensItemViewModel.Action, with coinModel: CoinModel) {
        switch action {
        case .info:
            // TODO: - Set need display alert for setup raiting voice user
            break
        case .add, .edit:
            let event: Analytics.Event = action == .add ? .manageTokensButtonAdd : .manageTokensButtonEdit
            Analytics.log(event: event, params: [.token: coinModel.id])

            coordinator.openTokenSelector(coinId: coinModel.id, with: coinModel.items.map { $0.tokenItem })
        }
    }

    private func updateGenerateAddressesViewModel() {
        let countWalletPendingDerivation = pendingDerivationCountByWalletId.filter { $0.value > 0 }.count

        guard countWalletPendingDerivation > 0 else {
            return generateAddressesViewModel = nil
        }

        Analytics.log(
            event: .manageTokensButtonGenerateAddresses,
            params: [.cardsCount: String(countWalletPendingDerivation)]
        )

        generateAddressesViewModel = GenerateAddressesViewModel(
            numberOfNetworks: pendingDerivationCountByWalletId.map { $0.value }.reduce(0, +),
            currentWalletNumber: pendingDerivationCountByWalletId.filter { $0.value > 0 }.count,
            totalWalletNumber: userWalletRepository.userWallets.count,
            didTapGenerate: weakify(self, forFunction: ManageTokensViewModel.generateAddressByWalletPendingDerivations)
        )
    }

    private func generateAddressByWalletPendingDerivations() {
        guard let userWalletId = pendingDerivationCountByWalletId.first(where: { $0.value > 0 })?.key else {
            return
        }

        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        userWalletModel.userTokensManager.deriveIfNeeded { result in
            if case .failure(let error) = result, !error.isUserCancelled {
                self.alert = error.alertBinder
            }
        }
    }
}
