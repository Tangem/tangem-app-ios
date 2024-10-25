//
//  OnrampProvidersViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class OnrampProvidersViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var providers: [OnrampProviderRowViewData] = [
        OnrampProviderRowViewData(
            id: "1inch",
            name: "1Inch",
            iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1INCH512.png"),
            formattedAmount: "0,00453 BTC",
            badge: .bestRate,
            action: {}
        ),
        OnrampProviderRowViewData(
            id: "changenow",
            name: "Changenow",
            iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/NOW512.png"),
            formattedAmount: "0,00450 BTC",
            badge: .percent("-0.03%", signType: .negative),
            action: {}
        ),
    ]
    @Published var selectedProviderId: String?

    // MARK: - Dependencies

    private weak var coordinator: OnrampProvidersRoutable?

    init(
        coordinator: OnrampProvidersRoutable
    ) {
        self.coordinator = coordinator
    }
}
