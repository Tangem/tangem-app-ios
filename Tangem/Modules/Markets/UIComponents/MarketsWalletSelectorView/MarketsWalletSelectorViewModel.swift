//
//  MarketsWalletSelectorViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class MarketsWalletSelectorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var icon: LoadingValue<CardImageResult> = .loading

    private let userWalletNamePublisher: AnyPublisher<String, Never>
    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>

    private var bag: Set<AnyCancellable> = []

    private let balanceFomatter = BalanceFormatter()

    // MARK: - Init

    init(
        userWalletNamePublisher: AnyPublisher<String, Never>,
        cardImagePublisher: AnyPublisher<CardImageResult, Never>
    ) {
        self.userWalletNamePublisher = userWalletNamePublisher
        self.cardImagePublisher = cardImagePublisher

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
    }
}
