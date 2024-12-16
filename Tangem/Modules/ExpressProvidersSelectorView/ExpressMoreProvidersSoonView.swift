//
//  ExpressMoreProvidersSoonView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 13.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressMoreProvidersSoonView: View {
    var body: some View {
        VStack(spacing: 4) {
            Assets.expressMoreProvidersIcon.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.inactive)

            Text(Localization.expressMoreProvidersSoon)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)
                .multilineTextAlignment(.center)
        }
    }
}
