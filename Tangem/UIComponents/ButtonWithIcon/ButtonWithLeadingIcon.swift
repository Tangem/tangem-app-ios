//
//  ButtonWithLeadingIcon.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FixedSizeButtonWithLeadingIcon: View {
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
            spacing: 4,
            maintainsIdealSize: true,
            action: action
        )
    }

    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let icon: Image
    private let action: () -> Void

    private var textColor: Color {
        isEnabled ? Colors.Text.primary1 : Colors.Text.disabled
    }

    private var iconColor: Color {
        isEnabled ? Colors.Icon.primary1 : Colors.Icon.inactive
    }

    private var backgroundColor: Color {
        isEnabled ? (backgroundColorOverride ?? Colors.Button.secondary) : Colors.Button.disabled
    }

    private var backgroundColorOverride: Color?

    init(
        title: String,
        icon: Image,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
}

struct FlexySizeButtonWithLeadingIcon: View {
    var body: some View {
        let colorConfiguration = ButtonWithLeadingIconContentView.ColorConfiguration(
            textColor: isToggled ? Colors.Text.tertiary : Colors.Text.primary1,
            iconColor: isToggled ? Colors.Icon.informative : Colors.Text.primary1,
            backgroundColor: backgroundColorOverride ?? Colors.Background.primary
        )
        ButtonWithLeadingIconContentView(
            title: title,
            icon: icon,
            colorConfiguration: colorConfiguration,
            spacing: 6,
            maintainsIdealSize: false,
            action: action
        )
    }

    private let title: String
    private let icon: Image
    /// A special appearance for cases when this button is used to switch between
    /// the discrete `On` and `Off` states, like `SwiftUI.Switch` does.
    /// See [this mockup](https://www.figma.com/file/ZJoUO3kZGCcVgOUbCMQcY4/iOS-%E2%80%93-UI?type=design&node-id=5333-16973&mode=design&t=GAR2V2mQICJTQ6XD-4)
    /// as an example of such behavior.
    private let isToggled: Bool
    private let action: () -> Void

    private var backgroundColorOverride: Color?

    init(
        title: String,
        icon: Image,
        isToggled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isToggled = isToggled
        self.action = action
    }
}

// MARK: - Setupable protocol conformance

extension FixedSizeButtonWithLeadingIcon: Setupable {
    func overrideBackgroundColor(_ color: Color) -> Self {
        return map { $0.backgroundColorOverride = color }
    }
}

extension FlexySizeButtonWithLeadingIcon: Setupable {
    func overrideBackgroundColor(_ color: Color) -> Self {
        return map { $0.backgroundColorOverride = color }
    }
}

// MARK: - Constants

extension FixedSizeButtonWithLeadingIcon {
    enum Constants {
        /// - Note: Exposed for consumers of this UI component.
        static var cornerRadius: CGFloat { ButtonWithLeadingIconContentView.cornerRadius }
    }
}

extension FlexySizeButtonWithLeadingIcon {
    enum Constants {
        /// - Note: Exposed for consumers of this UI component.
        static var cornerRadius: CGFloat { ButtonWithLeadingIconContentView.cornerRadius }
    }
}

// MARK: - Private implementation

private struct ButtonWithLeadingIconContentView: View {
    static let cornerRadius = 10.0

    struct ColorConfiguration {
        let textColor: Color
        let iconColor: Color
        let backgroundColor: Color
    }

    let title: String
    let icon: Image
    let colorConfiguration: ColorConfiguration
    let spacing: Double
    let maintainsIdealSize: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing) {
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
        .cornerRadiusContinuous(Self.cornerRadius)
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
