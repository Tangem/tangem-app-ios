//
//  MarketsWalletSelectorView.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct MarketsWalletSelectorView: View {
    @ObservedObject var viewModel: MarketsWalletSelectorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(Localization.marketsSelectWallet)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .padding(.horizontal, 14)

            ForEach(viewModel.itemViewModels) { itemViewModel in
                WalletSelectorItemView(viewModel: itemViewModel)
            }
        }
        .background(Colors.Background.action)
        .cornerRadiusContinuous(14)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    MarketsWalletSelectorView(
        viewModel: MarketsWalletSelectorViewModel(provider: PreviewMarketsWalletSelectorDataSourceStub())
    )
}
