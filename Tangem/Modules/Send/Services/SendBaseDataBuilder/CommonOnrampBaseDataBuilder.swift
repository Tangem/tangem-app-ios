//
//  CommonOnrampBaseDataBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine

struct CommonOnrampBaseDataBuilder {
//    private let tokenItem: TokenItem
    private let onrampRepository: OnrampRepository
    private let onrampDataRepository: OnrampDataRepository
//    private let onrampManager: OnrampManager
    private let providersBuilder: OnrampProvidersBuilder
    private let paymentMethodsBuilder: OnrampPaymentMethodsBuilder
    private let onrampRedirectingBuilder: OnrampRedirectingBuilder

    init(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
//        onrampManager: OnrampManager,
        providersBuilder: OnrampProvidersBuilder,
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) {
        self.onrampRepository = onrampRepository
        self.onrampDataRepository = onrampDataRepository
//        self.onrampManager = onrampManager
        self.providersBuilder = providersBuilder
        self.paymentMethodsBuilder = paymentMethodsBuilder
        self.onrampRedirectingBuilder = onrampRedirectingBuilder
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

    func makeDataForOnrampRedirecting() -> OnrampRedirectingBuilder {
        return onrampRedirectingBuilder
    }
}

enum OnrampBaseDataBuilderError: LocalizedError {
    case selectedProviderNotFound
}
