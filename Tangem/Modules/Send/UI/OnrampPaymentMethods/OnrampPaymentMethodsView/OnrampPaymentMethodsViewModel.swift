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
import TangemFoundation

final class OnrampPaymentMethodsViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var selectedPaymentMethod: String?
    @Published var paymentMethods: [OnrampPaymentMethodRowViewData] = []
    @Published var alert: AlertBinder?

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
                viewModel.selectedPaymentMethod = payment.id
            }
            .store(in: &bag)

        interactor
            .paymentMethodsPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, paymentMethods in
                viewModel.updateView(paymentMethods: paymentMethods)
            }
            .store(in: &bag)
    }

    func updateView(paymentMethods methods: [OnrampPaymentMethod]) {
        paymentMethods = methods.map { method in
            OnrampPaymentMethodRowViewData(
                id: method.id,
                name: method.name,
                iconURL: method.image,
                isSelected: selectedPaymentMethod == method.id,
                action: { [weak self] in
                    self?.selectedPaymentMethod = method.id
                    self?.interactor.update(selectedPaymentMethod: method)
                    self?.updateView(paymentMethods: methods)
                }
            )
        }
    }
}
