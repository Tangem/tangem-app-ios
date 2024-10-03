//
//  TokenSectionView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenSectionView: View {
    private let title: String?

    /// Not used on iOS versions below iOS 16.0.
    /// - Note: Although this property has no effect on iOS versions below iOS 16.0,
    /// it can't be marked using `@available` declaration in Swift 5.7 and above.
    private let topEdgeCornerRadius: CGFloat?

    var body: some View {
        if let title = title {
            OrganizeTokensListSectionView(title: title, isDraggable: false)
                .background(background)
        }
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 16.0, *), let topEdgeCornerRadius = topEdgeCornerRadius {
            Colors.Background.primary.cornerRadiusContinuous(
                topLeadingRadius: topEdgeCornerRadius,
                topTrailingRadius: topEdgeCornerRadius
            )
        } else {
            Colors.Background.primary
        }
    }
}

// MARK: - Initialization

extension TokenSectionView {
    @available(iOS 16.0, *)
    init(
        title: String?,
        cornerRadius: CGFloat?
    ) {
        self.title = title
        topEdgeCornerRadius = cornerRadius
    }

    @available(iOS, obsoleted: 16.0, message: "Use 'init(title:cornerRadius:)' instead")
    init(
        title: String?
    ) {
        self.title = title
        topEdgeCornerRadius = nil
    }
}

// MARK: - Previews

struct TokenSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TokenSectionView(title: "Ethereum")

            TokenSectionView(title: nil)

            TokenSectionView(title: "A token list section header view with an extremely long title...")
        }
    }
}
