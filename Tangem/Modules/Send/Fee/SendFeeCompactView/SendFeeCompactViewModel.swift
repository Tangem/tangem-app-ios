//
//  SendFeeCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SendFeeCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 76)
    @Published var selectedFeeRowViewModel: FeeRowViewModel?
    @Published var canEditFee: Bool = false

    private let feeTokenItem: TokenItem
    private let isFeeApproximate: Bool
    private var selectedFeeSubscription: AnyCancellable?
    private var canEditFeeSubscription: AnyCancellable?

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: BalanceFormatter(),
        balanceConverter: BalanceConverter()
    )

    init(
        input: SendFeeInput,
        feeTokenItem: TokenItem,
        isFeeApproximate: Bool
    ) {
        self.feeTokenItem = feeTokenItem
        self.isFeeApproximate = isFeeApproximate

        // Initial setup to exclude possible empty view
        selectedFeeRowViewModel = mapToFeeRowViewModel(fee: SendFee(option: .market, value: .loading))
    }

    func bind(input: SendFeeInput) {
        selectedFeeSubscription = input
            .selectedFeePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.selectedFeeRowViewModel = viewModel.mapToFeeRowViewModel(fee: selectedFee)
            }

        canEditFeeSubscription = input
            .feesPublisher
            .map { feeValues in
                let multipleFeeOptions = feeValues.count > 1
                let hasError = feeValues.contains { $0.value.error != nil }

                return multipleFeeOptions && !hasError
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.canEditFee, on: self, ownership: .weak)
    }

    private func mapToFeeRowViewModel(fee: SendFee) -> FeeRowViewModel {
        let feeComponents = fee.value.mapValue {
            feeFormatter.formattedFeeComponents(
                fee: $0.amount.value,
                currencySymbol: feeTokenItem.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: isFeeApproximate
            )
        }

        return FeeRowViewModel(option: fee.option, components: feeComponents, style: .plain)
    }
}
