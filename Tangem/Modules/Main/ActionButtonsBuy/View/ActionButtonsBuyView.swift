//
//  ActionButtonsBuyView.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsBuyView: View {
    @ObservedObject var viewModel: ActionButtonsBuyViewModel

    var body: some View {
        content
            .navigationTitle(Localization.actionButtonsBuyNavigationBarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismiss: { viewModel.handleViewAction(.close) })
                }
            }
            .transition(.opacity.animation(.easeInOut))
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
