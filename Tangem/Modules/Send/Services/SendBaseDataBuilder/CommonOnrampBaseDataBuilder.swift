//
//  CommonOnrampBaseDataBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampBaseDataBuilderInput {}

struct CommonOnrampBaseDataBuilder {
    private let tokenItem: TokenItem
    private let onrampRepository: OnrampRepository
    private let onrampDataRepository: OnrampDataRepository
    private let onrampManager: OnrampManager
    private let providersBuilder: OnrampProvidersBuilder
    private let paymentMethodsBuilder: OnrampPaymentMethodsBuilder

    init(
        tokenItem: TokenItem,
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        onrampManager: OnrampManager,
        providersBuilder: OnrampProvidersBuilder,
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder
    ) {
        self.tokenItem = tokenItem
        self.onrampRepository = onrampRepository
        self.onrampDataRepository = onrampDataRepository
        self.onrampManager = onrampManager
        self.providersBuilder = providersBuilder
        self.paymentMethodsBuilder = paymentMethodsBuilder
    }
}

// MARK: - OnrampBaseDataBuilder

extension CommonOnrampBaseDataBuilder: OnrampBaseDataBuilder {
    func makeDataForOnrampCountryBottomSheet() -> OnrampRepository {
        return onrampRepository
    }

    func makeDataForOnrampCountrySelectorView() -> (preferenceRepository: OnrampRepository, dataRepository: OnrampDataRepository) {
        return (preferenceRepository: onrampRepository, dataRepository: onrampDataRepository)
    }

    func makeDataForOnrampProvidersPaymentMethodsView() -> (providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder) {
        return (providersBuilder: providersBuilder, paymentMethodsBuilder: paymentMethodsBuilder)
    }

    func makeDataForOnrampRedirecting() -> (tokenItem: TokenItem, onrampManager: OnrampManager) {
        return (tokenItem: tokenItem, onrampManager: onrampManager)
    }
}
