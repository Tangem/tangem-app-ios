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
        VStack(alignment: .leading, spacing: 10) {
            Text(Localization.marketsSelectWallet)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            ForEach(viewModel.itemViewModels) { itemViewModel in
                WalletSelectorItemView(viewModel: itemViewModel)
            }
        }
        .background(Colors.Background.action)
        .frame(maxWidth: .infinity)
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: 14)
    }
}

#Preview {
    MarketsWalletSelectorView(
        viewModel: MarketsWalletSelectorViewModel(provider: PreviewMarketsWalletSelectorDataSourceStub())
    )
}
