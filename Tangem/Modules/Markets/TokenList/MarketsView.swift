//
//  MarketsView.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct MarketsView: View {
    @ObservedObject var viewModel: MarketsViewModel

    var body: some View {
        VStack {
            header

            list
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsCommonTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .lineLimit(1)

            MarketsRatingHeaderView(viewModel: viewModel.marketRatingHeaderViewModel)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var list: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokenViewModels) {
                MarketsItemView(viewModel: $0)
            }

            if viewModel.hasNextPage, viewModel.viewDidAppear {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                    .onAppear(perform: viewModel.fetchMore)
            }
        }
    }

    private var addCustomTokenView: some View {
        MarketsAddCustomItemView {
            // Need force hide keyboard, because it will affect the state of the focus properties field in the shield under the hood
            UIApplication.shared.endEditing()

            viewModel.addCustomTokenDidTapAction()
        }
    }
}
