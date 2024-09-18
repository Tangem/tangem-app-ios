//
//  MainBottomSheetHint.swift
//  Tangem
//
//  Created by skibinalexander on 17.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetHintView: View {
    let scrollOffset: CGPoint

    var body: some View {
        VStack {
            hintView
                .opacity(scrollOffset.y < 24 ? 0 : 1)
        }
        .frame(width: 160)
        .offset(y: -92)
    }

    private var hintView: some View {
        VStack(alignment: .center, spacing: .zero) {
            Text(Localization.marketsHint)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)

            Assets.chevronDown12.image
        }
    }
}
