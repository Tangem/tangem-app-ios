//
//  BottomSheetHeaderView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetHeaderView<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: () -> Leading
    private let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        leading: @escaping (() -> Leading) = { EmptyView() },
        trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .center) {
                Text(title)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                HStack(spacing: .zero) {
                    leading()

                    Spacer()

                    trailing()
                }
            }

            if let subtitle {
                Text(subtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(.vertical, 12)
    }
}
