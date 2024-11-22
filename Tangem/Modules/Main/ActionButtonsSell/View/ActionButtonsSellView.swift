//
//  ActionButtonsSellView.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsSellView: View {
    @ObservedObject var viewModel: ActionButtonsSellViewModel

    var body: some View {
        content
            .navigationTitle(Localization.commonSell)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: { viewModel.handleViewAction(.close) })
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            TokenSelectorView(
                viewModel: viewModel.tokenSelectorViewModel,
                tokenCellContent: { token in
                    ActionButtonsTokenSelectItemView(model: token) {
                        viewModel.handleViewAction(.didTapToken(token))
                    }
                    .padding(.vertical, 16)
                },
                emptySearchContent: {
                    Text(viewModel.tokenSelectorViewModel.strings.emptySearchMessage)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .animation(.default, value: viewModel.tokenSelectorViewModel.searchText)
                }
            )
            .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.ignoresSafeArea(.all))
    }
}
