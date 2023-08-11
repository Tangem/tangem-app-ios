//
//  BlockchainNetworkNavigationTitleView.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BlockchainNetworkNavigationTitleView: View {
    private let viewModel: BlockchainNetworkNavigationTitleViewModel

    init(viewModel: BlockchainNetworkNavigationTitleViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(viewModel.title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                IconView(
                    url: viewModel.iconURL,
                    size: CGSize(width: 14, height: 14)
                )

                Text(viewModel.networkName)
                    .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            }
        }
    }
}

struct BlockchainNetworkNavigationTitleView_Preview: PreviewProvider {
    static var previews: some View {
        BlockchainNetworkNavigationTitleView(
            viewModel: BlockchainNetworkNavigationTitleViewModel(
                title: Localization.swappingTokenListTitle,
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                network: "bitcoin"
            )
        )
    }
}
