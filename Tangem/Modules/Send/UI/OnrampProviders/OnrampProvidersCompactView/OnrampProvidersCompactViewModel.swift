//
//  OnrampProvidersCompactViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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
        ).map { [weak self] provider, paymentMethod -> PaymentState? in
            guard let provider, let paymentMethod else {
                return nil
            }

            return .loaded(
                data: .init(
                    iconURL: paymentMethod.identity.image,
                    paymentMethodName: paymentMethod.identity.name,
                    providerName: provider.provider.id,
                    badge: .bestRate,
                    action: {
                        self?.router?.onrampStepRequestEditProvider()
                    }
                )
            )
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.paymentState, on: self, ownership: .weak)
        .store(in: &bag)
    }
}

extension OnrampProvidersCompactViewModel {
    enum PaymentState: Hashable, Identifiable {
        case loading
        case loaded(data: OnrampProvidersCompactProviderViewData)

        var id: Int { hashValue }
    }
}
