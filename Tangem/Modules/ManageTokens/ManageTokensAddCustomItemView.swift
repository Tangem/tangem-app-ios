//
//  ManageTokensAddCustomItemView.swift
//  Tangem
//
//  Created by skibinalexander on 27.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ManageTokensAddCustomItemView: View {
    @ObservedObject var viewModel: ManageTokensItemViewModel

    private let iconSize = CGSize(bothDimensions: 46)

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)
                    .padding(.trailing, 12)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(viewModel.name)
                            .lineLimit(1)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(viewModel.symbol)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }

                    HStack(spacing: 4) {
                        Text(viewModel.priceValue)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                        TokenPriceChangeView(state: viewModel.priceChangeState)
                    }
                }

                Spacer(minLength: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .animation(nil) // Disable animations on scroll reuse
    }
}
