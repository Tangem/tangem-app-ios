//
//  ExpressFeeSelectorViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress
import struct BlockchainSdk.Fee

final class ExpressFeeSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var selectedFeeOption: FeeOption

    // MARK: - Dependencies

    private let feeFormatter: FeeFormatter
    private let expressInteractor: ExpressInteractor
    private weak var coordinator: ExpressFeeSelectorRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        feeFormatter: FeeFormatter,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressFeeSelectorRoutable
    ) {
        self.feeFormatter = feeFormatter
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        selectedFeeOption = expressInteractor.getState().fees.selected
        bind()
    }

    private func bind() {
        expressInteractor.state
            // Don't update the view when reloading
            // Because fees can be empty
            .filter { !$0.fees.fees.isEmpty }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.setupView(fees: state.fees)
            }
            .store(in: &bag)
    }

    private func setupView(fees: ExpressInteractor.Fees) {
        selectedFeeOption = fees.selected

        // Should use the option's array for the correct order
        feeRowViewModels = [FeeOption.market, .fast].compactMap { option in
            guard let fee = fees.fees[option] else {
                return nil
            }

            return makeFeeRowViewModel(option: option, fee: fee)
        }
    }

    private func makeFeeRowViewModel(option: FeeOption, fee: Fee) -> FeeRowViewModel {
        let tokenItem = expressInteractor.getSender().feeTokenItem
        let formattedFeeComponents = feeFormatter.formattedFeeComponents(fee: fee.amount.value, tokenItem: tokenItem)

        return FeeRowViewModel(
            option: option,
            components: .loaded(formattedFeeComponents),
            style: .selectable(
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == option
                }, set: { root, newValue in
                    if newValue {
                        root.expressInteractor.updateFeeOption(option: option)
                        root.selectedFeeOption = option
                        root.coordinator?.closeExpressFeeSelector()
                    }
                })
            )
        )
    }
}
