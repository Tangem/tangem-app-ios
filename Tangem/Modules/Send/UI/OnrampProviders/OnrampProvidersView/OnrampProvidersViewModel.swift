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

    @Published var paymentViewData: OnrampProvidersPaymentViewData?
    @Published var selectedProviderId: String?
    @Published var providersViewData: [OnrampProviderRowViewData] = []

    // MARK: - Dependencies

    private let interactor: OnrampProvidersInteractor
    private weak var coordinator: OnrampProvidersRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: OnrampProvidersInteractor,
        coordinator: OnrampProvidersRoutable
    ) {
        self.interactor = interactor
        self.coordinator = coordinator

        bind()
    }
}

// MARK: - Private

private extension OnrampProvidersViewModel {
    func bind() {
        interactor
            .selectedProviderPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, provider in
                // TODO: https://tangem.atlassian.net/browse/IOS-8310
                viewModel.selectedProviderId = provider.value?.provider.id
            }
            .store(in: &bag)

        interactor
            .paymentMethodPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, payment in
                viewModel.updatePaymentView(payment: payment)
            }
            .store(in: &bag)

        interactor
            .providesPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, providers in
                viewModel.updateProvidersView(providers: providers)
            }
            .store(in: &bag)
    }

    func updatePaymentView(payment: OnrampPaymentMethod) {
        paymentViewData = .init(
            name: payment.identity.name,
            iconURL: payment.identity.image,
            action: {}
        )
    }

    func updateProvidersView(providers: [OnrampProviderManager]) {
        providersViewData = providers.map { provider in
            OnrampProviderRowViewData(
                id: provider.provider.id,
                name: "1Inch",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1INCH512.png"),
                formattedAmount: "0,00453 BTC",
                badge: .bestRate,
                isSelected: selectedProviderId == provider.provider.id,
                action: { [weak self] in
                    self?.selectedProviderId = provider.provider.id
                    self?.updateProvidersView(providers: providers)
                    self?.interactor.update(selectedProvider: provider)
                }
            )
        }
    }
}
