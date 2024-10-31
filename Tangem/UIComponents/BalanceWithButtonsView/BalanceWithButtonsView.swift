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
                HStack {
                    Text(Localization.commonBalanceTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    Spacer()

                    balancePicker
                }

                BalanceTitleView(balance: viewModel.fiatBalance, isLoading: viewModel.isLoadingFiatBalance)

                SensitiveText(viewModel.cryptoBalance)
                    .skeletonable(isShown: viewModel.isLoadingBalance, size: .init(width: 70, height: 12))
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            ScrollableButtonsView(itemsHorizontalOffset: 14, buttonsInfo: viewModel.buttons)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    @ViewBuilder
    private var balancePicker: some View {
        if let balanceTypeValues = viewModel.balanceTypeValues {
            SegmentedPicker(
                selectedOption: $viewModel.selectedBalanceType,
                options: balanceTypeValues,
                shouldStretchToFill: false,
                isDisabled: false,
                style: .init(textVerticalPadding: 2)
            ) { $0.title }
        } else {
            EmptyView()
        }
    }
}

struct BalanceWithButtonsView_Previews: PreviewProvider {
    struct BalanceWithButtonsPreview: View {
        private let provider = FakeBalanceWithButtonsInfoProvider()

        var body: some View {
            Group {
                VStack {
                    balanceStateViews(models: provider.models, opacity: 1)
                }
                .padding()
                .frame(maxHeight: .infinity)
                .background(Colors.Background.secondary)
                .previewDisplayName("One by one")

                ZStack {
                    balanceStateViews(models: provider.modelsWithButtons, opacity: 0.1)
                }
                .padding()
                .frame(maxHeight: .infinity)
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .previewDisplayName("Overlaid")
            }
        }

        func balanceStateViews(models: [BalanceWithButtonsViewModel], opacity: Double) -> some View {
            ForEach(models, id: \.id) { model in
                BalanceWithButtonsView(viewModel: model)
                    .opacity(opacity)
            }
        }
    }

    static var previews: some View {
        BalanceWithButtonsPreview()
    }
}
