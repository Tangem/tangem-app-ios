//
//  MarketsListOrderBottonSheetView.swift
//  Tangem
//
//  Created by skibinalexander on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsListOrderBottonSheetView: View {
    @ObservedObject var viewModel: MarketsListOrderBottonSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: Localization.marketsSortByTitle)

            SelectableGropedSection(
                viewModel.listOptionViewModel,
                selection: $viewModel.currentOrderType,
                content: {
                    DefaultSelectableRowView(viewModel: $0)
                }
            )
            .backgroundColor(Colors.Background.action)
        }
        .padding(.horizontal, 16)
    }
}
