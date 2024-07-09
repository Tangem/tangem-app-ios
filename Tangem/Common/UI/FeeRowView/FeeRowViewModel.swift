//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FeeRowViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    let option: FeeOption
    let isSelected: BindingValue<Bool>
    private let formattedFeeComponents: LoadingValue<FormattedFeeComponents>

    var cryptoAmount: String? {
        switch formattedFeeComponents {
        case .loading:
            return ""
        case .loaded(let value):
            return value.cryptoFee
        case .failedToLoad:
            return AppConstants.dashSign
        }
    }

    var fiatAmount: String? {
        switch formattedFeeComponents {
        case .loading, .failedToLoad:
            // Corresponding UI will be displayed by the cryptoAmount field
            return nil
        case .loaded(let value):
            return value.fiatFee
        }
    }

    var isLoading: Bool {
        formattedFeeComponents.isLoading
    }

    init(
        option: FeeOption,
        formattedFeeComponents: LoadingValue<FormattedFeeComponents>,
        isSelected: BindingValue<Bool>
    ) {
        self.option = option
        self.formattedFeeComponents = formattedFeeComponents
        self.isSelected = isSelected
    }
}
