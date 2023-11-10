//
//  MainBottomSheetContentView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A temporary entity for integration and testing, subject to change.
struct MainBottomSheetContentView: View {
    @ObservedObject var viewModel: MainBottomSheetViewModel

    var body: some View {
        LazyVStack(spacing: .zero) {
            ForEach(viewModel.dataSource(), id: \.self) { index in
                Button(action: viewModel.toggleItem) {
                    Text(index)
                        .font(.title3)
                        .foregroundColor(Colors.Text.primary1.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.all)
                }

                Divider()
            }
        }
    }
}
