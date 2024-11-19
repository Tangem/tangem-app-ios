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
    let statusesList: [PendingExpressTxStatusRow.StatusRowData]
    let showGoToProviderHeaderButton: Bool
    let openProviderAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            headerView
            statusesView
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var headerView: some View {
        HStack {
            Text(title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Button(action: openProviderAction) {
                openProviderButtonLabel
            }
            .opacity(showGoToProviderHeaderButton ? 1.0 : 0.0)
        }
    }

    private var openProviderButtonLabel: some View {
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

    private var statusesView: some View {
        VStack(spacing: 0) {
            ForEach(statusesList.indexed(), id: \.1) { index, status in
                PendingExpressTxStatusRow(isFirstRow: index == 0, info: status)
            }
        }
    }
}
