//
//  CommonHeaderButtonView.swift
//  Tangem
//
//  Created by Alexander Skibin on 29.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct CommonHeaderButtonView: View {
    private(set) var title: String
    private(set) var button: ButtonInput
    private(set) var action: (() -> Void)?

    // MARK: - UI

    var body: some View {
        HStack(alignment: .center) {
            Text(Localization.marketsCommonMyPortfolio)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            addTokenButton
        }
    }

    private var headerView: some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.top, 15)
            .padding(.bottom, 9)
    }

    @ViewBuilder
    private var addTokenButton: some View {
        Button(action: {
            action?()
        }, label: {
            HStack(spacing: 2) {
                if let asset = button.asset {
                    asset.image
                        .foregroundStyle(button.isDisabled ? Colors.Icon.inactive : Colors.Icon.primary1)
                }

                Text(button.title)
                    .style(
                        Fonts.Regular.footnote.bold(),
                        color: button.isDisabled ? Colors.Icon.inactive : Colors.Text.primary1
                    )
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
        })
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(Constants.buttonCornerRadius)
        .skeletonable(isShown: button.isLoading, size: .init(width: 60, height: 18), radius: 3, paddings: .init(top: 3, leading: 0, bottom: 3, trailing: 0))
        .disabled(button.isDisabled)
    }
}

extension CommonHeaderButtonView {
    struct ButtonInput: Identifiable {
        let id: UUID = .init()

        let asset: ImageType?
        let title: String

        @Binding var isDisabled: Bool
        @Binding var isLoading: Bool
    }
}

private extension CommonHeaderButtonView {
    enum Constants {
        static let buttonCornerRadius: CGFloat = 8.0
    }
}
