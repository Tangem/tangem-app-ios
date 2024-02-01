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

    @Published var alert: AlertBinder?
    @Published var isShowAddCustomToken: Bool = false
    @Published var tokenViewModels: [ManageTokensItemViewModel] = []

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private weak var coordinator: ManageTokensRoutable?

    private var dataSource: ManageTokensDataSource
    private lazy var loader = setupListDataLoader()

    private var bag = Set<AnyCancellable>()
    private var cacheExistListCoinId: [String] = []
    private var pendingDerivationCountByWalletId: [UserWalletId: Int] = [:]

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: ManageTokensRoutable
    ) {
        self.coordinator = coordinator
        dataSource = ManageTokensDataSource()

        searchBind(searchTextPublisher: searchTextPublisher)

        bind()
    }

    func onAppear() {
        Analytics.log(.manageTokensScreenOpened)
        loader.reset("")
    }

    func fetchMore() {
        loader.fetchMore()
    }

    func addCustomTokenDidTapAction() {
        coordinator?.openAddCustomToken(dataSource: dataSource)
    }
}

// MARK: - Private Implementation

private extension ManageTokensViewModel {
    func fetch(with searchText: String = "") {
        loader.fetch(searchText)
    }

    /// Obtain supported token list from UserWalletModels to determine the cell action type
    /// Should be reset after updating the list of tokens
    func updateAlreadyExistTokenUserList() {
        let models = dataSource.userWalletModels

        let existEntriesList = models
            .flatMap {
                let userTokenListManager = $0.userTokenListManager
                let entries = userTokenListManager.userTokensList.entries
                return entries.compactMap { $0.isCustom ? nil : $0.id }
            }

        cacheExistListCoinId = existEntriesList
    }

    func searchBind(searchTextPublisher: (some Publisher<String, Never>)?) {
        searchTextPublisher?
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] value in
                if !value.isEmpty {
                    Analytics.log(.manageTokensSearched)
                }

                self?.setNeedDisplayTokensListSkeletonView()
                self?.fetch(with: value)
            }
            .store(in: &bag)
    }

    func bind() {
        dataSource
            .userWalletModelsPublisher
            .sink { [weak self] models in
                self?.updateAlreadyExistTokenUserList()
                self?.updateDerivationBind()
                self?.fetch()
            }
            .store(in: &bag)
    }

    func updateDerivationBind() {
        // Used for update state generateAddressesViewModel property
        let pendingDerivationsCountPublishers = dataSource.userWalletModels
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
        let userTokensPublishers = dataSource.userWalletModels
            .map { $0.userTokenListManager.userTokensPublisher }

        Publishers.MergeMany(userTokensPublishers)
            .receive(on: DispatchQueue.main)
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
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self = self else {
                    return
                }

                tokenViewModels = items.compactMap { self.mapToTokenViewModel(coinModel: $0) }
                updateQuote(by: items.map { $0.id })
                isShowAddCustomToken = tokenViewModels.isEmpty
            })
            .store(in: &bag)

        return loader
    }

    // MARK: - Private Implementation

    /// Need for display list skeleton view
    private func setNeedDisplayTokensListSkeletonView() {
        tokenViewModels = [Int](0 ... 10).map { _ in
            ManageTokensItemViewModel(
                coinModel: .dummy,
                priceValue: "----------",
                action: .info,
                state: .loading,
                didTapAction: { _, _ in }
            )
        }
    }

    private func actionType(for coinId: String) -> ManageTokensItemViewModel.Action {
        let isAlreadyExistToken = cacheExistListCoinId.contains(coinId)
        return isAlreadyExistToken ? .edit : .add
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel {
        ManageTokensItemViewModel(
            coinModel: coinModel,
            action: actionType(for: coinModel.id),
            state: .loaded,
            didTapAction: weakify(self, forFunction: ManageTokensViewModel.handle)
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

            coordinator?.openTokenSelector(
                dataSource: dataSource,
                coinId: coinModel.id,
                tokenItems: coinModel.items.map { $0.tokenItem }
            )
        }
    }

    private func updateGenerateAddressesViewModel() {
        let countWalletPendingDerivation = pendingDerivationCountByWalletId.filter { $0.value > 0 }.count

        guard countWalletPendingDerivation > 0 else {
            coordinator?.hideGenerateAddressesWarning()
            return
        }

        Analytics.log(
            event: .manageTokensButtonGenerateAddresses,
            params: [.cardsCount: String(countWalletPendingDerivation)]
        )

        coordinator?.showGenerateAddressesWarning(
            numberOfNetworks: pendingDerivationCountByWalletId.map(\.value).reduce(0, +),
            currentWalletNumber: pendingDerivationCountByWalletId.filter { $0.value > 0 }.count,
            totalWalletNumber: dataSource.userWalletModels.count,
            action: weakify(self, forFunction: ManageTokensViewModel.generateAddressByWalletPendingDerivations)
        )
    }

    private func generateAddressByWalletPendingDerivations() {
        guard let userWalletId = pendingDerivationCountByWalletId.first(where: { $0.value > 0 })?.key else {
            return
        }

        guard let userWalletModel = dataSource.userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        userWalletModel.userTokensManager.deriveIfNeeded { result in
            if case .failure(let error) = result, !error.isUserCancelled {
                self.alert = error.alertBinder
            }
        }
    }
}
