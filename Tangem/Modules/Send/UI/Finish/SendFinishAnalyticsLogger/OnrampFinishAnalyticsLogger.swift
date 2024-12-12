//
//  OnrampFinishAnalyticsLogger.swift
//  TangemApp
//
//  Created by Sergey Balashov on 03.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct OnrampFinishAnalyticsLogger: SendFinishAnalyticsLogger {
    private let tokenItem: TokenItem
    private weak var onrampProvidersInput: OnrampProvidersInput?

    init(tokenItem: TokenItem, onrampProvidersInput: OnrampProvidersInput) {
        self.tokenItem = tokenItem
        self.onrampProvidersInput = onrampProvidersInput
    }

    func onAppear() {
        guard let provider = onrampProvidersInput?.selectedOnrampProvider,
              let request = try? provider.makeOnrampQuotesRequestItem() else {
            return
        }

        Analytics.log(event: .onrampBuyingInProgressScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .provider: provider.provider.name,
            .paymentMethod: provider.paymentMethod.name,
            .residence: request.pairItem.country.identity.name,
            .currency: request.pairItem.fiatCurrency.identity.name,
        ])
    }
}
