//
//  ShopOrderProgressView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShopOrderProgressView: View {
    // Center-align activity indicator so that it is roughly in the same spot as the
    // activity indicator that will appear on the Order webview that will be opened
    // after this view
    var body: some View {
        Color.white
            .overlay(
                VStack {
                    SheetDragHandler()

                    Spacer()

                    ActivityIndicatorView(isAnimating: true, style: .medium, color: .tangemGrayDark)

                    Spacer()
                }
            )
            .overlay(
                Text(Localization.shopPlacingOrder)
                    .lineLimit(1)
                    .font(.system(size: 40, weight: .semibold))
                    .minimumScaleFactor(0.3)
                    .padding(.horizontal)
                    .offset(x: 0, y: -50)
            )
            .edgesIgnoringSafeArea(.all)
    }
}
