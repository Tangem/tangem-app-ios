//
//  SendAmountCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendAmountCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 143)
    @Published var amount: String?
    @Published var alternativeAmount: String?

    let tokenIconInfo: TokenIconInfo

    private let tokenItem: TokenItem
    private weak var input: SendAmountInput?

    private var bag: Set<AnyCancellable> = []

    init(
        input: SendAmountInput,
        tokenIconInfo: TokenIconInfo,
        tokenItem: TokenItem
    ) {
        self.input = input
        self.tokenIconInfo = tokenIconInfo
        self.tokenItem = tokenItem

        bind(input: input)
    }

    func bind(input: SendAmountInput) {
        input.amountPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.amount = amount?.format(currencySymbol: viewModel.tokenItem.currencySymbol)
                viewModel.alternativeAmount = amount?.formatAlternative(
                    currencySymbol: viewModel.tokenItem.currencySymbol
                )
            }
            .store(in: &bag)
    }
}
