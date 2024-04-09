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

    private var onFocusChanged: ((Bool) -> Void)?

    init(viewModel: SendCustomFeeInputFieldModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .lineLimit(1)

                HStack {
                    SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                        .prefixSuffixOptions(.suffix(text: "WEI", hasSpace: true))
                        .appearance(.init(font: Fonts.Regular.subheadline))
                        .onFocusChanged(onFocusChanged)

                    Spacer()

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
        .backgroundColor(Colors.Background.action)
    }
}

extension SendCustomFeeInputField: Setupable {
    func onFocusChanged(_ action: ((Bool) -> Void)?) -> Self {
        map { $0.onFocusChanged = action }
    }
}

#Preview {
    GroupedScrollView {
        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                amountPublisher: .just(output: 1234),
                fieldSuffix: "WEI",
                fractionDigits: 2,
                amountAlternativePublisher: .just(output: "0.41 $"),
                footer: "Maximum commission amount",
                onFieldChange: { _ in }
            )
        )

        SendCustomFeeInputField(
            viewModel: SendCustomFeeInputFieldModel(
                title: "Fee up to",
                amountPublisher: .just(output: 1234),
                fieldSuffix: "WEI",
                fractionDigits: 2,
                amountAlternativePublisher: .just(output: nil),
                footer: "Maximum commission amount",
                onFieldChange: { _ in }
            )
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
