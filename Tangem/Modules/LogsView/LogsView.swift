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
        .navigationTitle(Text("Logs"))
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu(viewModel.selectedCategory) {
                    ForEach(viewModel.categories.indexed(), id: \.1) { index, category in
                        Button(category, action: { viewModel.selectedCategoryIndex = index })
                    }
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
