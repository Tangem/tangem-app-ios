//
//  OnrampPaymentMethodsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress

final class OnrampPaymentMethodsViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var selectedPaymentMethod: String?
    @Published var paymentMethods: [OnrampPaymentMethodRowViewData] = []

    // MARK: - Dependencies

    private let interactor: OnrampPaymentMethodsInteractor
    private weak var coordinator: OnrampPaymentMethodsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: OnrampPaymentMethodsInteractor,
        coordinator: OnrampPaymentMethodsRoutable
    ) {
        self.interactor = interactor
        self.coordinator = coordinator

        bind()
    }
}

// MARK: - Private

private extension OnrampPaymentMethodsViewModel {
    func bind() {
        interactor
            .paymentMethodPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, payment in
                viewModel.selectedPaymentMethod = payment.identity.code
            }
            .store(in: &bag)

        interactor
            .paymentMethods
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, payments in
                viewModel.updateView(paymentMethods: payments)
            }
            .store(in: &bag)
    }

    func updateView(paymentMethods methods: [OnrampPaymentMethod]) {
        paymentMethods = methods.map { method in
            OnrampPaymentMethodRowViewData(
                id: method.identity.code,
                name: method.identity.name,
                iconURL: method.identity.image,
                isSelected: selectedPaymentMethod == method.identity.code,
                action: { [weak self] in
                    self?.selectedPaymentMethod = method.identity.code
                    self?.interactor.update(selectedPaymentMethod: method)
                    self?.updateView(paymentMethods: methods)
                }
            )
        }
    }
}
