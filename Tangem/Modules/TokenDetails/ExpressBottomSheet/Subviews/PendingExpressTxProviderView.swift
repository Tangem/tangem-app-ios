//
//  PendingExpressTxProviderView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 11.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxProviderView: View {
    let transactionID: String?
    let copyTransactionIDAction: () -> Void
    let providerRowViewModel: ProviderRowViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Localization.expressProvider)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if let transactionID {
                    Button(action: copyTransactionIDAction) {
                        HStack(spacing: 4) {
                            Assets.copy.image
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 16, height: 16)
                                .foregroundColor(Colors.Icon.informative)

                            Text(Localization.expressTransactionId(transactionID))
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                        .lineLimit(1)
                    }
                }
            }

            ProviderRowView(viewModel: providerRowViewModel)
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}
