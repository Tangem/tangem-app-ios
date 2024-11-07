//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by GuitarKitty on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

typealias ActionButtonsRoutable = ActionButtonsBuyRootRoutable & ActionButtonsSellRootRoutable & ActionButtonsSwapRootRoutable

final class ActionButtonsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    @Published private(set) var isButtonsDisabled = false

    // MARK: - Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel = BaseActionButtonViewModel(model: .sell)
    let swapActionButtonViewModel = BaseActionButtonViewModel(model: .swap)

    private var bag = Set<AnyCancellable>()

    private let expressTokensListAdapter: ExpressTokensListAdapter

    init(
        coordinator: some ActionButtonsRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter

        buyActionButtonViewModel = BuyActionButtonViewModel(
            model: .buy,
            coordinator: coordinator,
            userWalletModel: userWalletModel
        )

        bind()
        fetchData()
    }

    func fetchData() {
        TangemFoundation.runTask(in: self) {
            async let _ = $0.fetchSwapData()
        }
    }
}

// MARK: - Bind

private extension ActionButtonsViewModel {
    func bind() {
        bindWalletModels()
        bindAvailableExchange()
    }

    func bindWalletModels() {
        expressTokensListAdapter
            .walletModels()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels in
                self?.isButtonsDisabled = walletModels.isEmpty
            }
            .store(in: &bag)
    }

    func bindAvailableExchange() {
        exchangeService
            .initializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, isExchangeAvailable in
                TangemFoundation.runTask(in: viewModel) { viewModel in
                    if isExchangeAvailable {
                        await viewModel.sellActionButtonViewModel.updateState(to: .idle)
                        await viewModel.buyActionButtonViewModel.updateState(to: .idle)
                    } else {
                        await viewModel.sellActionButtonViewModel.updateState(to: .unexplicitLoading)
                        await viewModel.buyActionButtonViewModel.updateState(to: .unexplicitLoading)
                    }
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func fetchSwapData() async {
        // IOS-8238
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func fetchSellData() async {
        // IOS-8238
    }
}
