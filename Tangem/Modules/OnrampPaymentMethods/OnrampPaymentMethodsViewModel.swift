//
//  OnrampPaymentMethodsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class OnrampPaymentMethodsViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var selectedPaymentMethod: String = "card"
    @Published var paymentMethods: [OnrampPaymentMethodRowViewData] = []

    // MARK: - Dependencies

    private weak var coordinator: OnrampPaymentMethodsRoutable?

    init(
        coordinator: OnrampPaymentMethodsRoutable
    ) {
        self.coordinator = coordinator

        setupView()
    }
}

// MARK: - Private

private extension OnrampPaymentMethodsViewModel {
    func setupView() {
        paymentMethods = [
            .init(
                id: "card",
                name: "Card",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/OKX_512.png")!,
                isSelected: selectedPaymentMethod == "card",
                action: { [weak self] in
                    self?.selectedPaymentMethod = "card"
                    self?.setupView()
                }
            ),
            .init(
                id: "paypal",
                name: "PayPal",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW_512.png")!,
                isSelected: selectedPaymentMethod == "paypal",
                action: { [weak self] in
                    self?.selectedPaymentMethod = "paypal"
                    self?.setupView()
                }
            ),
        ]
    }
}
