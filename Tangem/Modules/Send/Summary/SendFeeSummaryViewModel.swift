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
    let id = UUID()

    let title: String
    let cryptoAmount: String
    let fiatAmount: String?

    @Published var titleVisible = true

    var feeName: String {
        feeOption.title
    }

    var feeIconImage: Image {
        feeOption.icon.image
    }

    private let feeOption: FeeOption
    private let animateTitleOnAppear: Bool

    init(title: String, feeOption: FeeOption, cryptoAmount: String, fiatAmount: String?, animateTitleOnAppear: Bool) {
        self.title = title
        self.feeOption = feeOption
        self.cryptoAmount = cryptoAmount
        self.fiatAmount = fiatAmount
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
