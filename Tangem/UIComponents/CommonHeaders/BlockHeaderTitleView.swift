//
//  BlockHeaderTitleView.swift
//  Tangem
//
//  Created by Alexander Skibin on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

/// This is a common component of the system design - a common header + button.
/// Required due to specific dimensions
struct BlockHeaderTitleView<TrailingView: View>: View {
    private typealias Constants = BlockHeaderConstants

    private let trailingItem: TrailingView?
    private let title: String

    // MARK: - Init

    init(title: String) {
        self.title = title
        trailingItem = nil
    }

    init(title: String, @ViewBuilder trailingItem: () -> TrailingView?) {
        self.title = title
        self.trailingItem = trailingItem()
    }

    // MARK: - UI

    var body: some View {
        HStack(spacing: .zero) {
            headerView

            Spacer(minLength: trailingItem == nil ? .zero : 8)

            if let trailingItem {
                trailingItem
                    .padding(.top, 12.0)
                    .padding(.bottom, 6.0)
            }
        }
    }

    private var headerView: some View {
        Text(title)
            .lineLimit(1)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
            .if(trailingItem == nil, transform: { view in
                view
                    .padding(.top, Constants.topPaddingTitle)
                    .padding(.bottom, Constants.topPaddingTitle)
            })
    }
}

private enum BlockHeaderConstants {
    static let topPaddingTitle: CGFloat = 12.0
    static let bottomPaddingTitle: CGFloat = 8.0
}

// MARK: - Helpers

extension BlockHeaderTitleView where TrailingView == EmptyView {
    init(title: String) {
        self.title = title
        trailingItem = nil
    }
}
