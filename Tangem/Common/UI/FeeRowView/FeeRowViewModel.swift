//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FeeRowViewModel: Identifiable {
    var id: Int {
        hashValue
    }

    let option: FeeOption
    let isSelected: BindingValue<Bool>

    var subtitleText: String {
        switch subtitle {
        case .loading:
            return ""
        case .loaded(let value):
            return value
        case .failedToLoad:
            return AppConstants.minusSign
        }
    }

    var isLoading: Bool {
        subtitle.isLoading
    }

    private let subtitle: LoadingValue<String>

    init(
        option: FeeOption,
        subtitle: LoadingValue<String>,
        isSelected: BindingValue<Bool>
    ) {
        self.option = option
        self.subtitle = subtitle
        self.isSelected = isSelected
    }
}

extension FeeRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(subtitle.value)
        hasher.combine(isSelected)
    }

    static func == (lhs: FeeRowViewModel, rhs: FeeRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
