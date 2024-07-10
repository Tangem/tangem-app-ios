//
//  MarketsPortfolioTokenItemView.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioTokenItemView: View {
    @ObservedObject var viewModel: MarketsPortfolioTokenItemViewModel
    
    // MARK: - UI
    
    var body: some View {
        EmptyView()
    }
}

#Preview {
    MarketsPortfolioTokenItemView(
        viewModel: .init(tokenItem: TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil)))
    )
}
