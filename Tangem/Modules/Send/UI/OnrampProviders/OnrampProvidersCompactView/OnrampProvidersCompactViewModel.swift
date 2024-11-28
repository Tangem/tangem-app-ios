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
import TangemFoundation

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

    private func updateView(provider: LoadingResult<OnrampProvider, Never>?) {
        switch (provider, provider?.value?.state) {
        case (.loading, _), (_, .loading):
            paymentState = .loading
        case (.success(let provider), .loaded),
             (.success(let provider), .restriction):
            paymentState = .loaded(
                data: makeOnrampProvidersCompactProviderViewData(provider: provider)
            )
        case (.none, _), (.success, _):
            paymentState = .none
        }
    }

    private func makeOnrampProvidersCompactProviderViewData(provider: OnrampProvider) -> OnrampProvidersCompactProviderViewData {
        OnrampProvidersCompactProviderViewData(
            iconURL: provider.paymentMethod.image,
            paymentMethodName: provider.paymentMethod.name,
            providerName: provider.provider.name,
            badge: provider.attractiveType == .best ? .bestRate : .none
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
