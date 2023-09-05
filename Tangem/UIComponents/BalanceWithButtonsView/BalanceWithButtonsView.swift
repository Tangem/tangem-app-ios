//
//  BalanceWithButtonsView.swift
//  Tangem
//
//  Created by Andrew Son on 31/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct BalanceWithButtonsView: View {
    @ObservedObject var viewModel: BalanceWithButtonsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Localization.onboardingBalanceTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                SensitiveText(viewModel.fiatBalance)
                    .multilineTextAlignment(.leading)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                    .skeletonable(isShown: viewModel.isLoadingFiatBalance, size: .init(width: 102, height: 24), radius: 6)
                    .frame(height: 34)

                SensitiveText(viewModel.cryptoBalance)
                    .skeletonable(isShown: viewModel.isLoadingBalance, size: .init(width: 70, height: 12))
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .frame(height: 18)
            }

            ScrollableButtonsView(itemsHorizontalOffset: 14, buttonsInfo: viewModel.buttons)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

struct BalanceWithButtonsView_Previews: PreviewProvider {
    struct BalanceWithButtonsPreview: View {
        private let provider = FakeBalanceWithButtonsInfoProvider()

        var body: some View {
            VStack {
                ForEach(provider.models, id: \.id) { model in
                    BalanceWithButtonsView(viewModel: model)
                }
            }
            .padding(.vertical, 10)
            .background(Colors.Background.secondary)
        }
    }

    static var previews: some View {
        BalanceWithButtonsPreview()
    }
}
