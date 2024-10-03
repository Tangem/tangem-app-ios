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
    var identifier: AnyHashable = 0 // Placeholder value when the view has no corresponding identifier from the VM
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
                    .overlay(
                        OrganizeTokensDragAndDropGestureMarkView(context: .init(identifier: identifier))
                            .frame(size: Constants.dragAndDropTapZoneSize)
                    )
            }
        }
        .padding(.horizontal, 14.0)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}

// MARK: - Constants

private extension OrganizeTokensListSectionView {
    enum Constants {
        static let dragAndDropTapZoneSize = CGSize(bothDimensions: 64.0)
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
