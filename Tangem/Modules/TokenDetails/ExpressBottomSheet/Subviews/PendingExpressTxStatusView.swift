//
//  PendingExpressTxStatusView.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 11.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxStatusView: View {
    let title: String
    let showGoToProviderHeaderButton: Bool
    let openProviderFromStatusHeader: () -> Void
    let statusesList: [PendingExpressTxStatusRow.StatusRowData]

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                Button(action: openProviderFromStatusHeader) {
                    HStack(spacing: 4) {
                        Assets.arrowRightUpMini.image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Colors.Text.tertiary)
                            .frame(size: .init(bothDimensions: 18))

                        Text(Localization.commonGoToProvider)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }
                .opacity(showGoToProviderHeaderButton ? 1.0 : 0.0)
            }

            VStack(spacing: 0) {
                ForEach(statusesList.indexed(), id: \.1) { index, status in
                    PendingExpressTxStatusRow(isFirstRow: index == 0, info: status)
                }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}
