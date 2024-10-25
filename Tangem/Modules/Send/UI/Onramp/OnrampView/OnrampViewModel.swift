//
//  OnrampViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OnrampViewModel: ObservableObject, Identifiable {
    @Published private(set) var onrampAmountViewModel: OnrampAmountViewModel
    @Published private(set) var paymentState: PaymentState?

    private let interactor: OnrampInteractor

    init(
        onrampAmountViewModel: OnrampAmountViewModel,
        interactor: OnrampInteractor
    ) {
        self.onrampAmountViewModel = onrampAmountViewModel
        self.interactor = interactor
    }
}

// MARK: - Private

private extension OnrampViewModel {
    func bind() {
        // TODO: Lisen interactor to update view
        // Temp mock
        paymentState = .loaded(
            data: .init(iconURL: nil, paymentMethodName: "Card", providerName: "1Inch", badge: .bestRate)
        )
    }
}

// MARK: - SendStepViewAnimatable

extension OnrampViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}


extension OnrampViewModel {
    enum PaymentState: Identifiable {
        var id: Int {
            switch self {
            case .loading:
                return "loading".hashValue
            case .loaded(let data):
                return data.id
            }
        }

        case loading
        case loaded(data: OnrampProvidersCompactViewData)
    }
}
