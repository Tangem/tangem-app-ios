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
    private let onrampRepository: OnrampRepository
    private let onrampDataRepository: OnrampDataRepository

    private let paymentMethodsBuilderIO: OnrampPaymentMethodsBuilder.IO
    private let providersBuilderIO: OnrampProvidersBuilder.IO

    init(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        paymentMethodsBuilderIO: OnrampPaymentMethodsBuilder.IO,
        providersBuilderIO: OnrampProvidersBuilder.IO
    ) {
        self.onrampRepository = onrampRepository
        self.onrampDataRepository = onrampDataRepository
        self.paymentMethodsBuilderIO = paymentMethodsBuilderIO
        self.providersBuilderIO = providersBuilderIO
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

    func makeDataForOnrampProvidersPaymentMethodsView() -> (paymentMethodsBuilder: OnrampPaymentMethodsBuilder, providersBuilder: OnrampProvidersBuilder) {
        (
            paymentMethodsBuilder: OnrampPaymentMethodsBuilder(io: paymentMethodsBuilderIO, dataRepository: onrampDataRepository),
            providersBuilder: OnrampProvidersBuilder(io: providersBuilderIO, paymentMethodsInput: paymentMethodsBuilderIO.input)
        )
    }
}
