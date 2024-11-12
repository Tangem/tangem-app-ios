//
//  OnrampProvidersCompactViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class OnrampProvidersCompactViewModel: ObservableObject {
    @Published private(set) var paymentState: PaymentState?

    weak var router: OnrampSummaryRoutable?

    private weak var providersInput: OnrampProvidersInput?
    private weak var paymentMethodInput: OnrampPaymentMethodsInput?

    private var bag: Set<AnyCancellable> = []

    init(providersInput: OnrampProvidersInput, paymentMethodInput: OnrampPaymentMethodsInput) {
        self.providersInput = providersInput
        self.paymentMethodInput = paymentMethodInput

        bind(providersInput: providersInput, paymentMethodInput: paymentMethodInput)
    }

    func bind(providersInput: OnrampProvidersInput, paymentMethodInput: OnrampPaymentMethodsInput) {
        Publishers.CombineLatest(
            providersInput.selectedOnrampProviderPublisher,
            paymentMethodInput.selectedOnrampPaymentMethodPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] provider, paymentMethod in
            self?.updateView(provider: provider, paymentMethod: paymentMethod)
        }
        .store(in: &bag)
    }

    func updateView(provider: LoadingValue<OnrampProvider>?, paymentMethod: OnrampPaymentMethod?) {
        switch (provider, paymentMethod) {
        case (.loading, _):
            paymentState = .loading
        case (.none, _), (.failedToLoad, _), (_, .none):
            paymentState = .none
        case (.loaded(let provider), .some(let paymentMethod)):
            paymentState = .loaded(
                data: .init(
                    iconURL: paymentMethod.identity.image,
                    paymentMethodName: paymentMethod.identity.name,
                    providerName: provider.provider.id,
                    badge: .bestRate
                ) { [weak self] in
                    self?.router?.onrampStepRequestEditProvider()
                }
            )
        }
    }
}

extension OnrampProvidersCompactViewModel {
    enum PaymentState: Hashable, Identifiable {
        case loading
        case loaded(data: OnrampProvidersCompactProviderViewData)

        var id: Int { hashValue }
    }
}
