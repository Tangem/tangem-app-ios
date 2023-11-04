//
//  ExpressFeeBottomSheetViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class ExpressFeeBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var selectedFeeOption: FeeOption = .market

    // MARK: - Dependencies

    private unowned let coordinator: ExpressFeeBottomSheetRoutable

    init(coordinator: ExpressFeeBottomSheetRoutable) {
        self.coordinator = coordinator
        setupView()
    }

    private func setupView() {
        feeRowViewModels = [FeeOption.market, .fast].map {
            makeFeeRowViewModel(option: $0)
        }
    }

    private func makeFeeRowViewModel(option: FeeOption) -> FeeRowViewModel {
        FeeRowViewModel(
            option: option,
            // TODO: Will be Implemented in https://tangem.atlassian.net/browse/IOS-4937
            subtitle: "0.159817 MATIC (0.22 $)",
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == option
            }, set: { root, newValue in
                if newValue {
                    root.selectedFeeOption = option
                    root.coordinator.closeExpressFeeBottomSheet()
                }
            })
        )
    }
}
