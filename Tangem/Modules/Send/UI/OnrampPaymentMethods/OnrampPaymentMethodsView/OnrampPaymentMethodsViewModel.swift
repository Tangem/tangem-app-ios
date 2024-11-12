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
    private let dataRepository: OnrampDataRepository
    private weak var coordinator: OnrampPaymentMethodsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: OnrampPaymentMethodsInteractor,
        dataRepository: OnrampDataRepository,
        coordinator: OnrampPaymentMethodsRoutable
    ) {
        self.interactor = interactor
        self.dataRepository = dataRepository
        self.coordinator = coordinator

        bind()
        setupView()
    }
}

// MARK: - Private

private extension OnrampPaymentMethodsViewModel {
    func setupView() {
        TangemFoundation.runTask(in: self) {
            let methods = try await $0.dataRepository.paymentMethods()
            await $0.updateView(paymentMethods: methods)
        }
    }

    func bind() {
        interactor
            .paymentMethodPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, payment in
                viewModel.selectedPaymentMethod = payment.identity.code
            }
            .store(in: &bag)
    }

    @MainActor
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
