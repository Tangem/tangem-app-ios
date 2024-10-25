//
//  OnrampProvidersViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress

final class OnrampProvidersViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var payment: OnrampProvidersPaymentViewData?
    @Published var selectedProviderId: String? = "1inch"
    @Published var providers: [OnrampProviderRowViewData] = []

    // MARK: - Dependencies

    private weak var coordinator: OnrampProvidersRoutable?

    init(coordinator: OnrampProvidersRoutable) {
        self.coordinator = coordinator

        setupView()
    }
}

// MARK: - Private

private extension OnrampProvidersViewModel {
    // TEMP MOCK
    func setupView() {
        payment = .init(
            iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/OKX_512.png")!,
            name: "Card",
            action: {}
        )

        providers = [
            OnrampProviderRowViewData(
                id: "1inch",
                name: "1Inch",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1INCH512.png"),
                formattedAmount: "0,00453 BTC",
                badge: .bestRate,
                isSelected: selectedProviderId == "1inch",
                action: { [weak self] in
                    self?.selectedProviderId = "1inch"
                    self?.setupView()
                }
            ),
            OnrampProviderRowViewData(
                id: "changenow",
                name: "Changenow",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW512.png"),
                formattedAmount: "0,00450 BTC",
                badge: .percent("-0.03%", signType: .negative),
                isSelected: selectedProviderId == "changenow",
                action: { [weak self] in
                    self?.selectedProviderId = "changenow"
                    self?.setupView()
                }
            ),
        ]
    }
}
