//
//  BottomSheetHeaderView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetHeaderView: View {
    private let title: String
    private let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            if let subtitle {
                Text(subtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.vertical, 12)
    }
}
