//
//  ScrollableButtonsView.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScrollableButtonsView: View {
    /// Use this property to expand scroll view beyond parent view
    /// This is usefull when your parent view has paddings, but scroll must
    /// go to the edge of the scree
    let itemsHorizontalOffset: CGFloat
    let buttonsInfo: [FixedSizeButtonWithIconInfo]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(buttonsInfo) { button in
                    FixedSizeButtonWithLeadingIcon(
                        title: button.title,
                        icon: button.icon.image,
                        style: button.style,
                        action: button.action,
                        longPressAction: button.longPressAction
                    )
                    .disabled(button.disabled)
                }
            }
            .padding(.horizontal, itemsHorizontalOffset)
        }
        .padding(.horizontal, -itemsHorizontalOffset)
    }
}

struct ScrollableButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ScrollableButtonsView(
                itemsHorizontalOffset: 16,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, disabled: true, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, disabled: true, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Receive", icon: Assets.arrowDownMini, disabled: true, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Exchange", icon: Assets.exchangeMini, disabled: false, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Organize tokens", icon: Assets.sliders, disabled: false, action: {}),
                    FixedSizeButtonWithIconInfo(title: "", icon: Assets.horizontalDots, disabled: true, action: {}),
                ]
            )

            ScrollableButtonsView(
                itemsHorizontalOffset: 0,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Receive", icon: Assets.arrowDownMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Exchange", icon: Assets.exchangeMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Organize tokens", icon: Assets.sliders, action: {}),
                    FixedSizeButtonWithIconInfo(title: "", icon: Assets.horizontalDots, action: {}),
                ]
            )

            ScrollableButtonsView(
                itemsHorizontalOffset: 0,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                ]
            )
        }
        .padding(.horizontal, 16)
    }
}
