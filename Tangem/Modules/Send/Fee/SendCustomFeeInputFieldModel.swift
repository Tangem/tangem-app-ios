//
//  SendCustomFeeInputFieldModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendCustomFeeInputFieldModel: ObservableObject, Identifiable {
    let title: String
    let fractionDigits: Int
    let footer: String

    var amount: Binding<DecimalNumberTextField.DecimalValue?>
    @Published var amountAlternative: String?

    private var bag: Set<AnyCancellable> = []

    init(
        title: String,
        amount: Binding<DecimalNumberTextField.DecimalValue?>,
        fractionDigits: Int,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        footer: String
    ) {
        self.title = title
        self.amount = amount
        self.fractionDigits = fractionDigits
        self.footer = footer

        amountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
