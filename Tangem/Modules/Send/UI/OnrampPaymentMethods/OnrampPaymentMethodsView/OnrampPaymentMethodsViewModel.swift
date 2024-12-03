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

    func onAppear() {
        Analytics.log(.onrampPaymentMethodScreenOpened)
    }
}

// MARK: - Private

private extension OnrampPaymentMethodsViewModel {
    func bind() {
        Publishers.CombineLatest(
            interactor.paymentMethodsPublisher.removeDuplicates(),
            interactor.paymentMethodPublisher.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .receive(on: DispatchQueue.main)
        .sink { viewModel, args in
            let (paymentMethods, payment) = args
            viewModel.updateView(paymentMethods: paymentMethods, selectedPaymentMethod: payment)
        }
        .store(in: &bag)
    }

    func updateView(paymentMethods methods: [OnrampPaymentMethod], selectedPaymentMethod: OnrampPaymentMethod) {
        paymentMethods = methods.map { method in
            OnrampPaymentMethodRowViewData(
                id: method.id,
                name: method.name,
                iconURL: method.image,
                isSelected: selectedPaymentMethod.id == method.id,
                action: { [weak self] in
                    self?.interactor.update(selectedPaymentMethod: method)
                    self?.updateView(paymentMethods: methods, selectedPaymentMethod: method)
                    self?.coordinator?.closeOnrampPaymentMethodsView()
                }
            )
        }
    }
}
