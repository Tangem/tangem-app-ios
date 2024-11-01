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

    private let tokenItem: TokenItem
    private let interactor: OnrampProvidersInteractor
    private weak var coordinator: OnrampProvidersRoutable?

    private let balanceFormatter = BalanceFormatter()

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        interactor: OnrampProvidersInteractor,
        coordinator: OnrampProvidersRoutable
    ) {
        self.tokenItem = tokenItem
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

        Publishers.CombineLatest(
            interactor.providesPublisher,
            interactor.paymentMethodPublisher
        )
        .map { providers, paymentMethod in
            providers.filter {
                $0.paymentMethod.identity.code == paymentMethod.identity.code
            }
        }
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
            action: { [weak self] in
                self?.coordinator?.openOnrampPaymentMethods()
            }
        )
    }

    func updateProvidersView(providers: [OnrampProvider]) {
        providersViewData = providers.map { provider in
            OnrampProviderRowViewData(
                id: provider.provider.id,
                name: provider.provider.name,
                iconURL: provider.provider.imageURL,
                formattedAmount: formattedAmount(state: provider.manager.state),
                state: state(state: provider.manager.state),
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

    func formattedAmount(state: OnrampProviderManagerState) -> String? {
        guard case .loaded(let onrampQuote) = state else {
            return nil
        }

        return balanceFormatter.formatCryptoBalance(
            onrampQuote.expectedAmount,
            currencyCode: tokenItem.currencySymbol
        )
    }

    func state(state: OnrampProviderManagerState) -> OnrampProviderRowViewData.State? {
        switch state {
        case .created, .loading:
            return nil
        case .failed(let error):
            return .error(error)
        case .loaded(let quote):
            return .available(time: "5 min")
        case .notSupported:
            return .unavailable
        }
    }
}
