//
//  WalletSelectorItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class WalletSelectorItemViewModel: ObservableObject, Identifiable {
    @Published var name: String = ""
    @Published var icon: LoadingValue<CardImageResult> = .loading
    @Published var cardsCount: String
    @Published var balanceState: LoadableTextView.State = .initialized
    @Published var isSelected: Bool = false

    let userWalletId: UserWalletId
    let isUserWalletLocked: Bool

    private let userWalletNamePublisher: AnyPublisher<String, Never>
    private let totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never>
    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>

    private var onTapWallet: ((UserWalletId) -> Void)?

    private var bag: Set<AnyCancellable> = []

    private let balanceFormatter = BalanceFormatter()

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        cardsCount: Int,
        isUserWalletLocked: Bool,
        userWalletNamePublisher: AnyPublisher<String, Never>,
        totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never>,
        cardImagePublisher: AnyPublisher<CardImageResult, Never>,
        isSelected: Bool,
        didTapWallet: ((UserWalletId) -> Void)?
    ) {
        self.userWalletId = userWalletId
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = Localization.cardLabelCardCount(cardsCount)
        self.userWalletNamePublisher = userWalletNamePublisher
        self.totalBalancePublisher = totalBalancePublisher
        self.cardImagePublisher = cardImagePublisher
        self.isSelected = isSelected
        onTapWallet = didTapWallet

        bind()
    }

    func bind() {
        userWalletNamePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, name in
                viewModel.name = name
            }
            .store(in: &bag)

        cardImagePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, image in
                viewModel.icon = .loaded(image)
            }
            .store(in: &bag)

        totalBalancePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                guard !viewModel.isUserWalletLocked else {
                    viewModel.balanceState = .loaded(text: Localization.commonLocked)
                    return
                }

                switch result {
                case .loading:
                    viewModel.balanceState = .loading
                case .loaded(let totalBalance):
                    guard totalBalance.allTokensBalancesIncluded else {
                        viewModel.balanceState = .loaded(text: BalanceFormatter.defaultEmptyBalanceString)
                        return
                    }

                    let formatted = viewModel.balanceFormatter.formatFiatBalance(totalBalance.balance)
                    viewModel.balanceState = .loaded(text: formatted)
                case .failedToLoad:
                    viewModel.balanceState = .loaded(text: Localization.commonUnreachable)
                }
            }
            .store(in: &bag)
    }

    func onTapAction() {
        onTapWallet?(userWalletId)
    }
}
