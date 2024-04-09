//
//  SendWalletInfoView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 28.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendWalletInfoView: View {
    let namespace: Namespace.ID

    let walletName: String
    let walletBalance: String

    var body: some View {
        VStack(spacing: 4) {
            Text(walletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: SendViewNamespaceId.walletName.rawValue, in: namespace)

            SensitiveText(walletBalance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: SendViewNamespaceId.walletBalance.rawValue, in: namespace)
        }
    }
}
