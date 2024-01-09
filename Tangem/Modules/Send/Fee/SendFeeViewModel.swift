//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendFeeViewModelInput {
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
    var tokenItem: TokenItem { get }

    func didSelectFeeOption(_ feeOption: FeeOption)
}

class SendFeeViewModel: ObservableObject {
    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []

    private let input: SendFeeViewModelInput
    private let feeOptions: [FeeOption]
    private let tokenItem: TokenItem
    private var bag: Set<AnyCancellable> = []

    private var feeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter(),
            fiatRatesProvider: SwappingRatesProvider()
        )
    }

    init(input: SendFeeViewModelInput) {
        self.input = input
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption
        tokenItem = input.tokenItem
        feeRowViewModels = makeFeeRowViewModels([:])

        bind()
    }

    private func bind() {
        input.feeValues
            .sink { [weak self] feeValues in
                guard let self else { return }
                feeRowViewModels = makeFeeRowViewModels(feeValues)
            }
            .store(in: &bag)
    }

    private func makeFeeRowViewModels(_ feeValues: [FeeOption: LoadingValue<Fee>]) -> [FeeRowViewModel] {
        let formattedFeeValues: [FeeOption: LoadingValue<String>] = feeValues.mapValues { fee in
            switch fee {
            case .loading:
                return .loading
            case .loaded(let value):
                let formattedValue = self.feeFormatter.format(
                    fee: value.amount.value,
                    tokenItem: tokenItem
                )
                return .loaded(formattedValue)
            case .failedToLoad(let error):
                return .failedToLoad(error: error)
            }
        }

        return feeOptions.map { option in
            let value = formattedFeeValues[option] ?? .loading

            return FeeRowViewModel(
                option: option,
                subtitle: value,
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == option
                }, set: { root, newValue in
                    if newValue {
                        root.selectedFeeOption = option
                        root.input.didSelectFeeOption(option)
                    }
                })
            )
        }
    }
}
