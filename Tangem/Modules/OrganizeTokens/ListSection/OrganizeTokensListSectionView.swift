//
//  OrganizeTokensListSectionView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListSectionView: View {
    let title: String
    let isDraggable: Bool

    var body: some View {
        HStack(spacing: 12.0) {
            Text(title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0.0)

            if isDraggable {
                Assets.OrganizeTokens.groupDragAndDropIcon
                    .image
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .padding(.horizontal, 14.0)
        .frame(height: 42.0)
    }
}

// MARK: - Previews

struct OrganizeTokensListSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                OrganizeTokensListSectionView(
                    title: "Bitcoin network",
                    isDraggable: true
                )

                OrganizeTokensListSectionView(
                    title: "Bitcoin network",
                    isDraggable: false
                )
            }
            .background(Colors.Background.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary)
    }
}
