//
//  CommonHeaderTitleView.swift
//  Tangem
//
//  Created by Alexander Skibin on 29.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

/// This is a common component of the system design - a common header + button.
/// Required due to specific dimensions
struct CommonHeaderTitleView: View {
    private(set) var title: String

    // MARK: - UI

    var body: some View {
        HStack {
            headerView

            Spacer()
        }
    }

    private var headerView: some View {
        Text(title)
            .lineLimit(1)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .padding(.top, Constants.topPaddingTitle)
            .padding(.bottom, Constants.topPaddingTitle)
    }
}

private extension CommonHeaderTitleView {
    enum Constants {
        static let topPaddingTitle: CGFloat = 12.0
        static let bottomPaddingTitle: CGFloat = 8.0
    }
}
