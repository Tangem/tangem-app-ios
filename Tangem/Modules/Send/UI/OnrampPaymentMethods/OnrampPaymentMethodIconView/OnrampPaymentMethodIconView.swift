//
//  OnrampPaymentMethodIconView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 25.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampPaymentMethodIconView: View {
    let url: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Colors.Background.tertiary)
                .frame(size: CGSize(width: 36, height: 36))
                // Background should be aways white
                .environment(\.colorScheme, .light)

            IconView(
                url: url,
                size: CGSize(width: 24, height: 24),
                cornerRadius: 0,
                // Kingfisher shows a grey background even if it has a cached image
                forceKingfisher: false
            )
        }
    }
}
