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

final class ActionButtonsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    @Published private(set) var actionButtonViewModels: [ActionButtonViewModel]
    @Published private(set) var isButtonsDisabled = false

    private var cancellables = Set<AnyCancellable>()

    private let actionButtonsFactory: ActionButtonsFactory
    private let expressTokensListAdapter: ExpressTokensListAdapter

    init(
        actionButtonsFactory: some ActionButtonsFactory,
        expressTokensListAdapter: some ExpressTokensListAdapter
    ) {
        self.actionButtonsFactory = actionButtonsFactory
        self.expressTokensListAdapter = expressTokensListAdapter
        actionButtonViewModels = actionButtonsFactory.makeActionButtonViewModels()

        bind()
        fetchData()
    }

    func fetchData() {
        TangemFoundation.runTask(in: self) {
            async let _ = $0.fetchBuyData()
            
            async let _ = $0.fetchSwapData()
            
            async let _ = $0.fetchSellData()
        }
    }

    func bind() {
        expressTokensListAdapter
            .walletModels()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels in
                self?.isButtonsDisabled = walletModels.isEmpty
            }
            .store(in: &cancellables)
    }
}

// MARK: - Buy

private extension ActionButtonsViewModel {
    private var buyActionButtonViewModel: ActionButtonViewModel? {
        actionButtonViewModels.first { $0.model == .buy }
    }

    private func fetchBuyData() async {
        // TODO: Should be modified in onramp
        await buyActionButtonViewModel?.updateState(to: .idle)
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    var swapActionButtonViewModel: ActionButtonViewModel? {
        actionButtonViewModels.first { $0.model == .swap }
    }

    func fetchSwapData() async {
        // IOS-8238
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    private var sellActionButtonViewModel: ActionButtonViewModel? {
        actionButtonViewModels.first { $0.model == .sell }
    }

    func fetchSellData() async {
        // IOS-8238
    }
}
