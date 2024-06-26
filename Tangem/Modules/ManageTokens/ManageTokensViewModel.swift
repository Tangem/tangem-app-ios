//
//  ManageTokensViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 30/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import SwiftUI

class ManageTokensViewModel: ObservableObject {
    var manageTokensListViewModel: ManageTokensListViewModel!

    @Published var customTokensList: [CustomTokenItemViewInfo] = []
    @Published var searchText = ""
    @Published var isPendingListEmpty = true
    @Published var isSavingChanges = false
    @Published var alert: AlertBinder?

    private let adapter: ManageTokensAdapter
    private let userTokensManager: UserTokensManager
    private let walletModelsManager: WalletModelsManager
    private weak var coordinator: ManageTokensRoutable?

    private let customTokensFullList = CurrentValueSubject<[CustomTokenItemViewInfo], Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        adapter: ManageTokensAdapter,
        userTokensManager: UserTokensManager,
        walletModelsManager: WalletModelsManager,
        coordinator: ManageTokensRoutable?
    ) {
        self.adapter = adapter
        self.userTokensManager = userTokensManager
        self.walletModelsManager = walletModelsManager
        self.coordinator = coordinator

        manageTokensListViewModel = .init(
            loader: self,
            coinViewModelsPublisher: adapter.coinViewModelsPublisher
        )

        bind()
    }

    func saveChanges() {
        isSavingChanges = true

        adapter.saveChanges { [weak self] result in
            guard let self else { return }

            isSavingChanges = false
            switch result {
            case .success:
                adapter.resetAdapter()
                showPortfolioUpdatedToast()
            case .failure(let failure):
                if failure.isUserCancelled {
                    return
                }

                alert = failure.alertBinder
            }
        }
    }

    func removeCustomToken(_ info: CustomTokenItemViewInfo) {
        let tokenItem = info.tokenItem
        if userTokensManager.canRemove(tokenItem) {
            alert = AlertBinder(
                alert: Alert(
                    title: Text(Localization.tokenDetailsHideAlertTitle(tokenItem.name)),
                    message: Text(Localization.tokenDetailsHideAlertMessage),
                    primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide), action: { [weak self] in
                        self?.userTokensManager.remove(tokenItem)
                        self?.showPortfolioUpdatedToast()
                    }),
                    secondaryButton: .cancel()
                )
            )
        } else {
            let title = Localization.tokenDetailsUnableHideAlertTitle(tokenItem.name)

            let message = Localization.tokenDetailsUnableHideAlertMessage(
                tokenItem.name,
                tokenItem.currencySymbol,
                tokenItem.blockchain.displayName
            )

            alert = AlertBinder(
                alert: Alert(
                    title: Text(title),
                    message: Text(message),
                    dismissButton: .default(Text(Localization.commonOk), action: {})
                )
            )
        }
    }

    private func bind() {
        adapter
            .isPendingListsEmptyPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPendingListEmpty, on: self, ownership: .weak)
            .store(in: &bag)

        adapter
            .alertPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.alert, on: self, ownership: .weak)
            .store(in: &bag)

        $searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.adapter.fetch(searchText)
            }
            .store(in: &bag)

        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .combineLatest(customTokensFullList)
            .map { searchText, tokensList in
                if searchText.isEmpty {
                    return tokensList
                }

                return tokensList.filter {
                    $0.name.range(of: searchText, options: .caseInsensitive) != nil ||
                        $0.symbol.range(of: searchText, options: .caseInsensitive) != nil
                }
            }
            .assign(to: \.customTokensList, on: self, ownership: .weak)
            .store(in: &bag)

        walletModelsManager.walletModelsPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { viewModel, walletModels in
                viewModel.prepareCustomTokensList(from: walletModels)
            }
            .assign(to: \.value, on: customTokensFullList, ownership: .weak)
            .store(in: &bag)
    }

    private func prepareCustomTokensList(from walletModels: [WalletModel]) -> [CustomTokenItemViewInfo] {
        let iconInfoBuilder = TokenIconInfoBuilder()
        return walletModels.compactMap {
            guard $0.isCustom else {
                return nil
            }

            return .init(
                tokenItem: $0.tokenItem,
                iconInfo: iconInfoBuilder.build(from: $0.tokenItem, isCustom: true),
                name: $0.name,
                symbol: $0.tokenItem.currencySymbol
            )
        }
    }

    private func showPortfolioUpdatedToast() {
        Toast(view: SuccessToast(text: Localization.manageTokensToastPortfolioUpdated))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}

extension ManageTokensViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        adapter.hasNextPage
    }

    func fetch() {
        adapter.fetch(searchText)
    }
}

// MARK: - Navigation

extension ManageTokensViewModel {
    func openAddCustomToken() {
        coordinator?.openAddCustomToken()
    }
}
