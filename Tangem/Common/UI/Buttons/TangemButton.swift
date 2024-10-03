//
//  TangemButton.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TangemButton: View {
    let title: String
    var image: String = ""
    var systemImage: String = ""
    var iconPosition: IconPosition = .leading
    var iconPadding: CGFloat = 8
    let action: () -> Void

    @ViewBuilder
    private var icon: some View {
        if !image.isEmpty {
            Image(image)
        } else if !systemImage.isEmpty {
            Image(systemName: systemImage)
        } else {
            EmptyView()
        }
    }

    private var hasImage: Bool {
        !image.isEmpty || !systemImage.isEmpty
    }

    @ViewBuilder
    private var label: some View {
        Text(title)
            .lineLimit(2)
            .transition(.opacity)
            .id("tangem_button_\(title)")
    }

    var body: some View {
        Button(action: action, label: {
            if !hasImage {
                label
            } else {
                Group {
                    if iconPosition == .leading {
                        icon
                        Color.clear.frame(width: iconPadding, height: iconPadding)
                        label
                    } else {
                        label
                        Color.clear.frame(width: iconPadding, height: iconPadding)
                        icon
                    }
                }
            }
        })
    }
}

extension TangemButton {
    enum IconPosition {
        case leading
        case trailing
    }

    static func vertical(
        title: String,
        image: String = "",
        systemImage: String = "",
        action: @escaping () -> Void
    ) -> TangemButton {
        return TangemButton(
            title: title,
            image: image,
            systemImage: systemImage,
            iconPosition: .leading,
            iconPadding: 2,
            action: action
        )
    }
}

struct TangemButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TangemButton(title: "Recharge de portefeuille", image: "scan") {}
                .buttonStyle(TangemButtonStyle(colorStyle: .black))

            TangemButton(title: "Scan", image: "scan") {}
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .black,
                    layout: .big
                ))

            TangemButton(
                title: Localization.commonExplore,
                systemImage: "chevron.right",
                iconPosition: .trailing
            ) {}
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .transparentWhite,
                    layout: .wide
                ))

            HStack {
                TangemButton(
                    title: Localization.commonSend,
                    image: "scan"
                ) {}
                    .buttonStyle(TangemButtonStyle(
                        layout: .smallVertical,
                        isLoading: true
                    ))

                TangemButton.vertical(
                    title: Localization.commonBuy,
                    systemImage: "arrow.up"
                ) {}
                    .buttonStyle(TangemButtonStyle(layout: .smallVertical))

                TangemButton.vertical(
                    title: "Scan",
                    systemImage: "arrow.right"
                ) {}
                    .buttonStyle(TangemButtonStyle(layout: .smallVertical))
            }
            .padding(.horizontal, 8)
        }
        .environment(\.locale, .init(identifier: "fr"))
        .previewGroup()
    }
}
