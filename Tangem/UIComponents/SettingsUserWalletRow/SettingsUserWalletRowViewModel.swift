//
//  SettingsUserWalletRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SettingsUserWalletRowViewModel: ObservableObject, Identifiable {
    @Published var name: String = ""
    @Published var icon: LoadingValue<CardImageResult> = .loading
    @Published var cardsCount: String
    @Published var balanceState: LoadableTokenBalanceView.State = .loading()
    let tapAction: () -> Void

    let isUserWalletLocked: Bool
    private let userWalletNamePublisher: AnyPublisher<String, Never>
    private let totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>
    private var bag: Set<AnyCancellable> = []

    private let balanceFormatter = BalanceFormatter()

    convenience init(userWallet: UserWalletModel, tapAction: @escaping () -> Void) {
        self.init(
            cardsCount: userWallet.cardsCount,
            isUserWalletLocked: userWallet.isUserWalletLocked,
            userWalletNamePublisher: userWallet.userWalletNamePublisher,
            totalBalancePublisher: userWallet.totalBalancePublisher,
            cardImagePublisher: userWallet.cardImagePublisher,
            tapAction: tapAction
        )
    }

    init(
        cardsCount: Int,
        isUserWalletLocked: Bool,
        userWalletNamePublisher: AnyPublisher<String, Never>,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>,
        cardImagePublisher: AnyPublisher<CardImageResult, Never>,
        tapAction: @escaping () -> Void
    ) {
        self.cardsCount = Localization.cardLabelCardCount(cardsCount)
        self.isUserWalletLocked = isUserWalletLocked
        self.userWalletNamePublisher = userWalletNamePublisher
        self.totalBalancePublisher = totalBalancePublisher
        self.cardImagePublisher = cardImagePublisher
        self.tapAction = tapAction
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
            .sink { $0.setupBalanceState(state: $1) }
            .store(in: &bag)
    }

    private func setupBalanceState(state: TotalBalanceState) {
        guard !isUserWalletLocked else {
            balanceState = .loaded(text: Localization.commonLocked)
            return
        }

        balanceState = LoadableTokenBalanceViewStateBuilder().buildTotalBalance(state: state)
    }
}
