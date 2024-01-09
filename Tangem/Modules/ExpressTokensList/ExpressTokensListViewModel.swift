//
//  ExpressTokensListViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class ExpressTokensListViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var searchText: String = ""
    @Published var viewState: ViewState = .idle

    var unavailableSectionHeader: String {
        Localization.exchangeTokensUnavailableTokensHeader(swapDirection.name)
    }

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let expressRepository: ExpressRepository
    private let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressTokensListRoutable

    // MARK: - Internal

    private var availableWalletModels: [WalletModel] = []
    private var unavailableWalletModels: [WalletModel] = []
    private var bag: Set<AnyCancellable> = []

    // For Analytics
    private var selectedWallet: WalletModel?

    init(
        swapDirection: SwapDirection,
        expressTokensListAdapter: ExpressTokensListAdapter,
        expressRepository: ExpressRepository,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressTokensListRoutable
    ) {
        self.swapDirection = swapDirection
        self.expressTokensListAdapter = expressTokensListAdapter
        self.expressRepository = expressRepository
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
    }

    func onDisappear() {
        if let wallet = selectedWallet {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [
                    .tokenChosen: Analytics.ParameterValue.yes.rawValue,
                    .token: wallet.tokenItem.currencySymbol,
                ]
            )
        } else {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [
                    .tokenChosen: Analytics.ParameterValue.no.rawValue,
                ]
            )
        }
    }
}

// MARK: - Private

private extension ExpressTokensListViewModel {
    func bind() {
        expressTokensListAdapter.walletModels()
            .withWeakCaptureOf(self)
            .asyncMap { viewModel, walletModels in
                let availablePairs = await viewModel.loadAvailablePairs()
                return (walletModels: walletModels, pairs: availablePairs)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels, pairs in
                self?.updateWalletModels(walletModels: walletModels, availableCurrencies: pairs)
            }
            .store(in: &bag)

        $searchText
            .removeDuplicates()
            .dropFirst()
            .flatMapLatest { searchText in
                // We don't add debounce for the empty text
                if searchText.isEmpty {
                    return Just(searchText).eraseToAnyPublisher()
                }

                return Just(searchText)
                    .delay(for: .seconds(0.3), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] searchText in
                self?.updateView(searchText: searchText)
            }
            .store(in: &bag)
    }

    func loadAvailablePairs() async -> [ExpressCurrency] {
        switch swapDirection {
        case .fromSource(let wallet):
            let pairs = await expressRepository.getPairs(from: wallet)
            return pairs.map { $0.destination }
        case .toDestination(let wallet):
            let pairs = await expressRepository.getPairs(to: wallet)
            return pairs.map { $0.source }
        }
    }

    func updateWalletModels(walletModels: [WalletModel], availableCurrencies: [ExpressCurrency]) {
        availableWalletModels.removeAll()
        unavailableWalletModels.removeAll()

        let currenciesSet = availableCurrencies.toSet()
        Analytics.log(.swapChooseTokenScreenOpened, params: [.availableTokens: currenciesSet.isEmpty ? .no : .yes])

        walletModels
            .forEach { walletModel in
                guard walletModel != swapDirection.wallet else { return }

                let isAvailable = currenciesSet.contains(walletModel.expressCurrency)
                let isNotCustom = !walletModel.isCustom
                if isAvailable, isNotCustom {
                    availableWalletModels.append(walletModel)
                } else {
                    unavailableWalletModels.append(walletModel)
                }
            }

        updateView()
    }

    func updateView(searchText: String = "") {
        let availableTokens = availableWalletModels
            .filter { filter(searchText, item: $0.tokenItem) }
            .map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: false)
            }

        let unavailableTokens = unavailableWalletModels
            .filter { filter(searchText, item: $0.tokenItem) }
            .map { walletModel in
                mapToExpressTokenItemViewModel(walletModel: walletModel, isDisable: true)
            }

        if searchText.isEmpty, availableTokens.isEmpty, unavailableTokens.isEmpty {
            viewState = .isEmpty
        } else {
            viewState = .loaded(availableTokens: availableTokens, unavailableTokens: unavailableTokens)
        }
    }

    func filter(_ text: String, item: TokenItem) -> Bool {
        if text.isEmpty {
            return true
        }

        let isContainsName = item.name.lowercased().contains(text.lowercased())
        let isContainsCurrencySymbol = item.currencySymbol.lowercased().contains(text.lowercased())

        return isContainsName || isContainsCurrencySymbol
    }

    func mapToExpressTokenItemViewModel(walletModel: WalletModel, isDisable: Bool) -> ExpressTokenItemViewModel {
        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        return ExpressTokenItemViewModel(
            id: walletModel.id,
            tokenIconInfo: tokenIconInfo,
            name: walletModel.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: walletModel.balance,
            fiatBalance: walletModel.fiatBalance,
            isDisable: isDisable,
            itemDidTap: { [weak self] in
                self?.userDidTap(on: walletModel)
            }
        )
    }

    func userDidTap(on walletModel: WalletModel) {
        switch swapDirection {
        case .fromSource:
            expressInteractor.update(destination: walletModel)
        case .toDestination:
            expressInteractor.update(sender: walletModel)
        }

        selectedWallet = walletModel
        coordinator.closeExpressTokensList()
    }
}

extension ExpressTokensListViewModel {
    enum ViewState {
        case idle
        case loading
        case isEmpty
        case loaded(availableTokens: [ExpressTokenItemViewModel], unavailableTokens: [ExpressTokenItemViewModel])
    }

    enum SwapDirection {
        case fromSource(WalletModel)
        case toDestination(WalletModel)

        var name: String {
            switch self {
            case .fromSource(let walletModel):
                return walletModel.name
            case .toDestination(let walletModel):
                return walletModel.name
            }
        }

        var wallet: WalletModel {
            switch self {
            case .fromSource(let walletModel):
                return walletModel
            case .toDestination(let walletModel):
                return walletModel
            }
        }
    }
}
