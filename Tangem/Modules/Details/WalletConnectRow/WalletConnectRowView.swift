//
//  WalletConnectRow.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectRowView: View {
    private let viewModel: WalletConnectRowViewModel

    init(viewModel: WalletConnectRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.action) {
            HStack(spacing: 12) {
                Assets.walletConnect.image
                    .resizable()
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(viewModel.subtitle)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
                .lineLimit(1)

                Spacer()

                Assets.chevron.image
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
