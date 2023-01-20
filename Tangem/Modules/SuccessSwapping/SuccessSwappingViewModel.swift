//
//  SuccessSwappingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SuccessSwappingViewModel: ObservableObject {
    // MARK: - ViewState

    var sourceFormatted: String {
        inputModel.sourceCurrencyAmount.formatted
    }

    var resultFormatted: String {
        inputModel.resultCurrencyAmount.formatted
    }

    var isViewInExplorerAvailable: Bool {
        inputModel.explorerURL != nil
    }

    // MARK: - Dependencies

    private let inputModel: SuccessSwappingInputModel
    private unowned let coordinator: SuccessSwappingRoutable

    init(
        inputModel: SuccessSwappingInputModel,
        coordinator: SuccessSwappingRoutable
    ) {
        self.inputModel = inputModel
        self.coordinator = coordinator
    }

    func didTapViewInExplorer() {
        coordinator.openExplorer(
            url: inputModel.explorerURL,
            currencyName: inputModel.sourceCurrencyAmount.currency.name
        )
    }

    func didTapClose() {
        coordinator.didTapCloseButton()
    }
}
