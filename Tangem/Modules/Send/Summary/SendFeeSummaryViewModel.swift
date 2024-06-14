//
//  SendFeeSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendFeeSummaryViewModel: ObservableObject, Identifiable {
    let title: String
    @Published var titleVisible = true

    var feeName: String {
        feeOption.title
    }

    var feeIconImage: Image {
        feeOption.icon.image
    }

    var cryptoAmount: String? {
        switch formattedFeeComponents {
        case .loading:
            return ""
        case .loaded(let value):
            return value?.cryptoFee
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
            return value?.fiatFee
        }
    }

    var isLoading: Bool {
        formattedFeeComponents.isLoading
    }

    let feeOption: FeeOption
    private var animateTitleOnAppear: Bool = false

    private let formattedFeeComponents: LoadingValue<FormattedFeeComponents?>

    init(title: String, feeOption: FeeOption, formattedFeeComponents: LoadingValue<FormattedFeeComponents?>) {
        self.title = title
        self.feeOption = feeOption
        self.formattedFeeComponents = formattedFeeComponents
    }

    func setAnimateTitleOnAppear(_ animateTitleOnAppear: Bool) {
        self.animateTitleOnAppear = animateTitleOnAppear
    }

    func onAppear() {
        if animateTitleOnAppear {
            titleVisible = false
            withAnimation(SendView.Constants.defaultAnimation) {
                titleVisible = true
            }
        }
    }
}
