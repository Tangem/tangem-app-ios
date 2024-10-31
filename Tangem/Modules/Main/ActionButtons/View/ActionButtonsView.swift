//
//  ActionButtonsView.swift
//  Tangem
//
//  Created by GuitarKitty on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.actionButtonViewModels) {
                ActionButtonView(viewModel: $0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .task {
            await viewModel.fetchData()
        }
    }
}
