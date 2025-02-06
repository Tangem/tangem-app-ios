//
//  LogsView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 22.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct LogsView: View {
    @ObservedObject var viewModel: LogsViewModel

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: .zero) {
            content
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(viewModel.categories.indexed(), id: \.1) { index, category in
                        Button(category, action: { viewModel.selectedCategoryIndex = index })
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedCategory)

                        Assets.chevron.image
                            .renderingMode(.template)
                            .rotationEffect(.degrees(90))
                            .frame(width: 10, height: 10)
                    }
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.share) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.logs {
        case .loading:
            ProgressView()
                .infinityFrame()
        case .success(let logs):
            ForEach(logs, id: \.id) {
                LogRowView(data: $0)

                Divider()
            }
        case .failure(let failure):
            Text(failure.localizedDescription)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .infinityFrame()
        }
    }
}
