//
//  SendCustomFeeInputFieldModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import SwiftUI

class SendCustomFeeInputFieldModel: ObservableObject, Identifiable {
    let title: String
    let fractionDigits: Int
    let footer: String

    @Published var amount: DecimalNumberTextField.DecimalValue? = nil
    @Published var amountAlternative: String?

    private var bag: Set<AnyCancellable> = []
    private let onFieldChange: (DecimalNumberTextField.DecimalValue?) -> Void

    init(
        title: String,
        amountPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never>,
        fractionDigits: Int,
        amountAlternativePublisher: AnyPublisher<String?, Never>,
        footer: String,
        onFieldChange: @escaping (DecimalNumberTextField.DecimalValue?) -> Void
    ) {
        self.title = title
        self.fractionDigits = fractionDigits
        self.footer = footer
        self.onFieldChange = onFieldChange

        amountPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { (self, amount) in
                guard amount?.value != self.amount?.value else { return }
                self.amount = amount
            }
            .store(in: &bag)

        $amount
            .removeDuplicates { $0?.value == $1?.value }
            .dropFirst()
            .filter { $0?.isInternal ?? true }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { (self, value) in
                self.onFieldChange(value)
            }
            .store(in: &bag)

        amountAlternativePublisher
            .assign(to: \.amountAlternative, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
