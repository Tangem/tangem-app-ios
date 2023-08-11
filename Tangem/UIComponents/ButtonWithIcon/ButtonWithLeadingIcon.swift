//
//  ButtonWithLeadingIcon.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FixedSizeButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: textColor,
            iconColor: iconColor,
            backgroundColor: backgroundColor
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            maintainsIdealSize: true,
            action: action
        )
    }

    @Environment(\.isEnabled) private var isEnabled

    private var textColor: Color {
        isEnabled ? Colors.Text.primary1 : Colors.Text.disabled
    }

    private var iconColor: Color {
        isEnabled ? Colors.Icon.primary1 : Colors.Icon.inactive
    }

    private var backgroundColor: Color {
        isEnabled ? Colors.Button.secondary : Colors.Button.disabled
    }
}

struct FlexySizeButtonWithLeadingIcon: View {
    let title: String
    let icon: Image
    /// A special appearance for cases when this button is used to switch between
    /// the discrete `On` and `Off` states, like `SwiftUI.Switch` does.
    /// See [this mockup](https://www.figma.com/file/ZJoUO3kZGCcVgOUbCMQcY4/iOS-%E2%80%93-UI?type=design&node-id=5333-16973&mode=design&t=GAR2V2mQICJTQ6XD-4)
    /// as an example of such behavior.
    var isToggled: Bool = false
    let action: () -> Void

    var body: some View {
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: isToggled ? Colors.Text.secondary : Colors.Text.primary1,
            iconColor: isToggled ? Colors.Text.secondary : Colors.Text.primary1,
            backgroundColor: Colors.Background.primary
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            maintainsIdealSize: false,
            action: action
        )
    }
}

// MARK: - Private implementation

private struct ButtonWithLeadingIconContentView: View {
    struct ColorConfiguration {
        let textColor: Color
        let iconColor: Color
        let backgroundColor: Color
    }

    let title: String
    let icon: Image
    let colorConfiguration: ColorConfiguration
    let maintainsIdealSize: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundColor(colorConfiguration.iconColor)

                if !title.isEmpty {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: colorConfiguration.textColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: maintainsIdealSize, vertical: maintainsIdealSize)
                }
            }
            .frame(maxWidth: maintainsIdealSize ? nil : .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colorConfiguration.backgroundColor)
        }
        .cornerRadiusContinuous(10)
        .buttonStyle(.borderless)
    }
}

// MARK: - Previews

struct ButtonWithLeadingIcon_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
                .opacity(0.1)
                .ignoresSafeArea()

            VStack {
                FixedSizeButtonWithLeadingIcon(
                    title: "Buy",
                    icon: Assets.plusMini.image
                ) {}

                FixedSizeButtonWithLeadingIcon(
                    title: "Exchange",
                    icon: Assets.exchangeMini.image,
                    action: {}
                )
                .disabled(true)

                FixedSizeButtonWithLeadingIcon(
                    title: "Organize tokens",
                    icon: Assets.sliders.image
                ) {}

                FixedSizeButtonWithLeadingIcon(
                    title: "",
                    icon: Assets.horizontalDots.image,
                    action: {}
                )
                .disabled(true)

                FixedSizeButtonWithLeadingIcon(
                    title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                    icon: Assets.infoIconMini.image
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Buy",
                    icon: Assets.plusMini.image
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Exchange",
                    icon: Assets.exchangeMini.image,
                    isToggled: true
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "",
                    icon: Assets.horizontalDots.image
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "Organize tokens",
                    icon: Assets.sliders.image,
                    isToggled: true
                ) {}

                FlexySizeButtonWithLeadingIcon(
                    title: "LongTitle_LongTitle_LongTitle_LongTitle_LongTitle",
                    icon: Assets.infoIconMini.image
                ) {}
            }
            .padding(.horizontal)
            .infinityFrame()
        }
    }
}
