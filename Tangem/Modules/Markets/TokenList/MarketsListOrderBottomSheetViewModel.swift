//
//  MarketsListOrderBottomSheetViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt
import SwiftUI

class MarketsListOrderBottomSheetViewModel: ObservableObject, Identifiable {
    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<MarketsListOrderType>]
    @Published var currentOrderType: MarketsListOrderType

    // MARK: - Private Properties

    private var subscription: AnyCancellable?
    private var dismiss: (() -> Void)?

    private let provider: MarketsListDataFilterProvider

    // MARK: - Init

    init(from provider: MarketsListDataFilterProvider, onDismiss: (() -> Void)?) {
        dismiss = onDismiss
        currentOrderType = provider.currentFilterValue.order

        listOptionViewModel = provider.supportedOrderTypes.map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.description,
                subtitle: nil
            )
        }

        self.provider = provider

        bind()
    }

    private func bind() {
        subscription = $currentOrderType
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, newOption in
                viewModel.update(option: newOption)
            })
    }

    private func update(option: MarketsListOrderType) {
        currentOrderType = option
        provider.didSelectMarketOrder(option)
        dismiss?()
    }
}
