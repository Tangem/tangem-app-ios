//
//  SendCustomFeeInputField.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCustomFeeInputField: View {
    @ObservedObject var viewModel: SendCustomFeeInputFieldModel

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .lineLimit(1)

                HStack {
                    DecimalNumberTextField(
                        decimalValue: viewModel.amount,
                        decimalNumberFormatter: .init(maximumFractionDigits: viewModel.fractionDigits),
                        font: Fonts.Regular.subheadline
                    )

                    if let amountAlternative = viewModel.amountAlternative {
                        Text(amountAlternative)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 14)
        } footer: {
            Text(viewModel.footer)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }
}

#Preview {
    GroupedScrollView {
        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                amount: .constant(.internal(1234)),
                fractionDigits: 2,
                amountAlternativePublisher: .just(output: "0.41 $"),
                footer: "Maximum commission amount"
            )
        )

        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                amount: .constant(.internal(1234)),
                fractionDigits: 2,
                amountAlternativePublisher: .just(output: nil),
                footer: "Maximum commission amount"
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
