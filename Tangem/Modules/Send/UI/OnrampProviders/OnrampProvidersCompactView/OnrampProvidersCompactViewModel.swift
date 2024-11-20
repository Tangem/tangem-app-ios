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

    private var bag: Set<AnyCancellable> = []

    init(providersInput: OnrampProvidersInput) {
        bind(providersInput: providersInput)
    }

    private func bind(providersInput: OnrampProvidersInput) {
        providersInput
            .selectedOnrampProviderPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] provider in
                self?.updateView(provider: provider)
            }
            .store(in: &bag)
    }

    private func updateView(provider: LoadingValue<OnrampProvider>?) {
        switch provider {
        case .loading:
            paymentState = .loading
        case .loaded(let provider) where provider.manager.state.error == .none:
            paymentState = .loaded(
                data: makeOnrampProvidersCompactProviderViewData(provider: provider)
            )
        case .none, .failedToLoad, .loaded:
            paymentState = .none
        }
    }

    private func makeOnrampProvidersCompactProviderViewData(provider: OnrampProvider) -> OnrampProvidersCompactProviderViewData {
        OnrampProvidersCompactProviderViewData(
            iconURL: provider.paymentMethod.image,
            paymentMethodName: provider.paymentMethod.name,
            providerName: provider.provider.name,
            badge: provider.isBest ? .bestRate : .none
        ) { [weak self] in
            self?.router?.onrampStepRequestEditProvider()
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
