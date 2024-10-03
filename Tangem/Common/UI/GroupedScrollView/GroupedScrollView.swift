//
//  GroupedScrollView.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct GroupedScrollView<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let content: () -> Content

    private var interContentPadding: CGFloat = 0
    private var horizontalPadding: CGFloat = 16

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: alignment, spacing: spacing, content: content)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, interContentPadding)
        }
    }
}

extension GroupedScrollView: Setupable {
    func interContentPadding(_ padding: CGFloat) -> Self {
        map { $0.interContentPadding = padding }
    }
}

struct GroupedScrollView_Previews: PreviewProvider {
    static var previews: some View {
        GroupedScrollView {
            let viewModels = [
                DefaultRowViewModel(title: Localization.detailsChat, action: {}),
                DefaultRowViewModel(title: Localization.detailsRowTitleContactToSupport, action: {}),
            ]

            GroupedSection(viewModels) {
                DefaultRowView(viewModel: $0)
            } footer: {
                DefaultFooterView("Colors.Background.secondary.edgesIgnoringSafeArea(.all)")
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
