//
//  CommonHeaderTitleButtonView.swift
//  Tangem
//
//  Created by Alexander Skibin on 29.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

/// This is a common component of the system design - a common header + button.
/// Required due to specific dimensions
struct CommonHeaderTitleButtonView: View {
    let title: String
    let button: ButtonInput
    let action: (() -> Void)?

    // MARK: - UI

    var body: some View {
        HStack(alignment: .center) {
            headerView

            Spacer()

            addTokenButton
        }
    }

    private var headerView: some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.top, Constants.topPaddingTitle)
            .padding(.bottom, Constants.topPaddingTitle)
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

extension CommonHeaderTitleButtonView {
    struct ButtonInput: Identifiable {
        let id: UUID = .init()

        let asset: ImageType?
        let title: String
        let isDisabled: Bool
        let isLoading: Bool
    }
}

private extension CommonHeaderTitleButtonView {
    enum Constants {
        static let buttonCornerRadius: CGFloat = 8.0
        static let topPaddingTitle: CGFloat = 15.0
        static let bottomPaddingTitle: CGFloat = 9.0
    }
}
