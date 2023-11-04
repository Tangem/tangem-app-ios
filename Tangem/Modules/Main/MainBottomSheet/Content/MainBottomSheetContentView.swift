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
    @ObservedObject var viewModel: MainBottomSheetContentViewModel

    var body: some View {
        if let viewModel = viewModel.manageTokensViewModel {
            ManageTokensView(viewModel: viewModel)
                .onAppear { viewModel.onAppear(with: "") }
        }
    }
}
