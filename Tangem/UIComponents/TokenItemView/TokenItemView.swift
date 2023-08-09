//
//  TokenItemView.swift
//  Tangem
//
//  Created by Andrew Son on 24/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemView: View {
    @ObservedObject var viewModel: TokenItemViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            HStack(alignment: .center, spacing: 12) {
                TokenItemViewLeadingComponent(
                    name: viewModel.name,
                    imageURL: viewModel.imageURL,
                    blockchainIconName: viewModel.blockchainIconName,
                    isColorless: viewModel.isColorlessIcon
                )

                TokenItemViewMiddleComponent(
                    name: viewModel.name,
                    balance: viewModel.balanceCrypto,
                    hasPendingTransactions: viewModel.hasPendingTransactions,
                    isWithError: viewModel.networkUnreachable || viewModel.missingDerivation
                )

                Spacer(minLength: 0.0)

                TokenItemViewTrailingComponent(
                    isWithError: viewModel.networkUnreachable || viewModel.missingDerivation,
                    errorMessage: viewModel.trailingErrorMessage,
                    balanceFiat: viewModel.balanceFiat,
                    changePercentage: viewModel.changePercentage
                )
            }
        }
        .padding(14)
    }
}

struct TokenItemView_Previews: PreviewProvider {
    static let infoProvider = FakeTokenItemInfoProvider(walletManagers: [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager])

    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(infoProvider.viewModels, id: \.id) { model in
                TokenItemView(viewModel: model)
            }
        }
    }
}
