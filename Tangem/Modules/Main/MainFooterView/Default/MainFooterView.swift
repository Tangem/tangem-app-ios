//
//  MainFooterView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainFooterView: View {
    let viewModel: MainFooterViewModel

    let didScrollToBottom: Bool

    private let buttonSize: MainButton.Size = .default

    private var buttonPadding: EdgeInsets {
        let horizontalInset = 16.0
        return EdgeInsets(top: 14.0, leading: horizontalInset, bottom: 0.0, trailing: horizontalInset)
    }

    private var overlayViewTopPadding: CGFloat {
        // 75pt is derived from mockups
        return -max(75.0 - buttonPadding.top - buttonSize.height, 0.0)
    }

    var body: some View {
        VStack(spacing: 0.0) {
            MainButton(
                title: viewModel.buttonTitle,
                size: buttonSize,
                isDisabled: viewModel.isButtonDisabled,
                action: viewModel.buttonAction
            )
            .padding(buttonPadding)

            EmptyMainFooterView()
        }
        .background(
            ListFooterOverlayShadowView()
                .padding(.top, overlayViewTopPadding)
                .hidden(didScrollToBottom)
        )
    }
}
