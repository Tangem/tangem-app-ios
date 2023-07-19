//
//  TotalSumBalanceView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 11.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct TotalSumBalanceView: View {
    @ObservedObject var viewModel: TotalSumBalanceViewModel

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var currencyType: String = "USD"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(Localization.mainPageBalance)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)

                Spacer()

                Button(action: viewModel.didTapOnCurrencySymbol) {
                    HStack(spacing: 6) {
                        Text(currencyType)
                            .lineLimit(1)
                            .font(.system(size: 13, weight: .medium))

                        Assets.tangemArrowDown.image
                    }
                    .foregroundColor(.tangemGrayLight7)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 4)

            balanceView

            messageView
        }
    }

    private var balanceView: some View {
        VStack(alignment: .leading, spacing: 6) {
            AttributedTextView(viewModel.totalFiatValueString)
                .foregroundColor(Color.tangemGrayDark6)
                .skeletonable(isShown: viewModel.isLoading, size: CGSize(width: 100, height: 25))
                .frame(height: 33)
        }
    }

    @ViewBuilder
    private var messageView: some View {
        if viewModel.hasError {
            Text(Localization.mainProcessingFullAmount)
                .foregroundColor(Color.tangemWarning)
                .font(.system(size: 13, weight: .regular))
                .padding(.top, 2)
        }
    }
}
