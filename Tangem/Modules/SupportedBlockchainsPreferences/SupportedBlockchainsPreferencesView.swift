//
//  SupportedBlockchainsPreferencesView.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportedBlockchainsPreferencesView: View {
    @ObservedObject var viewModel: SupportedBlockchainsPreferencesViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.blockchainViewModels) {
                DefaultToggleRowView(viewModel: $0)
            }
        }
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationTitle(Text("Supported blockchains"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
