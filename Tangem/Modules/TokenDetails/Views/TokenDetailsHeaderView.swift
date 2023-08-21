//
//  TokenDetailsHeaderView.swift
//  Tangem
//
//  Created by Andrew Son on 20/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsHeaderView: View {
    let viewModel: TokenDetailsHeaderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(viewModel.tokenName)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)

                Spacer()

                IconView(url: viewModel.tokenIconModel.imageURL, sizeSettings: .tokenDetails)
            }

            HStack(spacing: 6) {
                Text(viewModel.networkPrefix)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                if let networkIconName = viewModel.networkIconName {
                    Image(networkIconName)
                        .resizable()
                        .frame(size: .init(bothDimensions: 18))
                }

                if let networkSuffix = viewModel.networkSuffix {
                    Text(networkSuffix)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    private static var tokenItem: TokenItem {
        .token(.inverseBTCBlaBlaBlaMock, .polygon(testnet: false))
        //        .blockchain(.avalanche(testnet: false))
        //        .token(.sushiMock, .ethereum(testnet: false))
    }

    static var previews: some View {
        TokenDetailsHeaderView(viewModel: .init(tokenItem: tokenItem))
    }
}
