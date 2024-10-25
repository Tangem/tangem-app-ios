//
//  OnrampCountryView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampCountryView: View {
    @ObservedObject private var viewModel: OnrampCountryViewModel

    init(viewModel: OnrampCountryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 24) {
            BottomSheetHeaderView(title: Localization.onrampResidencyBottomsheetTitle)

            contentView

            buttons
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
    }

    private var contentView: some View {
        VStack(spacing: 12) {
            IconView(url: viewModel.iconURL, size: CGSize(width: 36, height: 36), forceKingfisher: true)

            VStack(spacing: 6) {
                Text(viewModel.title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                switch viewModel.style {
                case .info:
                    Text(Localization.onrampResidencyBottomsheetCountrySubtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                case .notSupport:
                    Text(Localization.onrampResidencyBottomsheetCountryNotSupported)
                        .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                }
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.commonChange,
                style: .secondary,
                action: viewModel.didTapChangeButton
            )

            MainButton(
                title: viewModel.mainButtonTitle,
                action: viewModel.didTapMainButton
            )
        }
    }
}
