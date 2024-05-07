//
//  MainButton.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//
import SwiftUI

struct MainButton: View {
    private let title: String
    private let subtitle: String?
    private let icon: Icon?
    private let style: Style
    private let size: Size
    private let isDisabled: Bool
    private let action: () -> Void

    private var isLoading: Bool

    init(
        title: String,
        subtitle: String? = nil,
        icon: Icon? = nil,
        style: Style = .primary,
        size: Size = .default,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping (() -> Void)
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    init(settings: Settings) {
        self.init(
            title: settings.title,
            subtitle: settings.subtitle,
            icon: settings.icon,
            style: settings.style,
            size: settings.size,
            isLoading: settings.isLoading,
            isDisabled: settings.isDisabled,
            action: settings.action
        )
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, minHeight: size.height, maxHeight: size.height, alignment: .center)
                .background(style.background(isDisabled: isDisabled))
                .cornerRadiusContinuous(style.cornerRadius(for: size))
                .overlay(border)
        }
        .buttonStyle(BorderlessButtonStyle())
        // Prevents an ugly opacity effect when the button is placed on a transparent background and pressed
        .background(
            Colors.Background.primary
                .cornerRadiusContinuous(style.cornerRadius(for: size))
        )
        .disabled(isDisabled || isLoading)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            switch icon {
            case .none:
                titleView

            case .leading(let icon):
                HStack(alignment: .center, spacing: 6) {
                    iconView(icon: icon)

                    titleView
                }
            case .trailing(let icon):
                HStack(alignment: .center, spacing: 6) {
                    titleView

                    iconView(icon: icon)
                }
            }

            subtitleView
        }
        .padding(.horizontal, 16)
        .hidden(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: style.loaderColor()))
            }
        }
    }

    @ViewBuilder
    private var titleView: some View {
        Text(title)
            .style(
                style.titleFont(for: size),
                color: style.titleColor(isDisabled: isDisabled)
            )
            .lineLimit(1)
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let subtitle {
            Text(subtitle)
                .style(Fonts.Regular.caption2, color: style.subtitleColor())
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func iconView(icon: ImageType) -> some View {
        icon.image
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundColor(style.iconColor(isDisabled: isDisabled))
    }

    @ViewBuilder
    private var border: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius(for: size), style: .continuous)
            .stroke(style.border(isDisabled: isDisabled) ?? Color.clear)
    }
}

extension MainButton {
    enum Icon: Hashable {
        case leading(_ icon: ImageType)
        case trailing(_ icon: ImageType)
    }

    enum Style: String, Hashable, CaseIterable {
        case primary
        case secondary
        case exchangePromotionWhite
        case whiteTransparent

        func iconColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Icon.inactive
            }

            switch self {
            case .primary:
                return Colors.Icon.primary2
            case .secondary:
                return Colors.Icon.primary1
            case .exchangePromotionWhite, .whiteTransparent:
                return Colors.Text.expressPromotionButton
            }
        }

        func titleFont(for size: MainButton.Size) -> Font {
            switch size {
            case .default:
                return Fonts.Bold.callout
            case .notification:
                return Fonts.Bold.subheadline
            }
        }

        func titleColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Text.disabled
            }

            switch self {
            case .primary:
                return Colors.Text.primary2
            case .secondary:
                return Colors.Text.primary1
            case .exchangePromotionWhite, .whiteTransparent:
                return Colors.Text.expressPromotionButton
            }
        }

        func subtitleColor() -> Color {
            Colors.Text.disabled
        }

        func loaderColor() -> Color {
            switch self {
            case .primary:
                return Colors.Text.primary2
            case .secondary, .exchangePromotionWhite, .whiteTransparent:
                return Colors.Text.primary1
            }
        }

        func background(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Button.disabled
            }

            switch self {
            case .primary:
                return Colors.Button.primary
            case .secondary:
                return Colors.Button.secondary
            case .exchangePromotionWhite:
                return Colors.Button.expressPromotion
            case .whiteTransparent:
                return Color.white.opacity(0.3)
            }
        }

        func border(isDisabled: Bool) -> Color? {
            guard isDisabled else {
                return nil
            }

            return Colors.Stroke.primary
        }

        func cornerRadius(for size: MainButton.Size) -> Double {
            switch size {
            case .default:
                return 14
            case .notification:
                return 10
            }
        }
    }

    enum Size: Hashable {
        /// Height: 46
        case `default`
        /// Height: 40
        case notification

        var height: CGFloat {
            switch self {
            case .default: return 46
            case .notification: return 40
            }
        }
    }

    struct Settings: Identifiable, Hashable {
        let title: String
        let subtitle: String?
        let icon: Icon?
        let style: Style
        let size: Size
        let isLoading: Bool
        var isDisabled: Bool
        let action: () -> Void

        var id: Int { hashValue }

        init(
            title: String,
            subtitle: String? = nil,
            icon: Icon? = nil,
            style: Style = .primary,
            size: Size = .default,
            isLoading: Bool = false,
            isDisabled: Bool = false,
            action: @escaping (() -> Void)
        ) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.style = style
            self.size = size
            self.isLoading = isLoading
            self.isDisabled = isDisabled
            self.action = action
        }

        static func == (lhs: MainButton.Settings, rhs: MainButton.Settings) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(subtitle)
            hasher.combine(icon)
            hasher.combine(style)
            hasher.combine(size)
            hasher.combine(isLoading)
            hasher.combine(isDisabled)
        }
    }
}

extension MainButton: Setupable {
    func setIsLoading(to isLoading: Bool) -> Self {
        map { $0.isLoading = isLoading }
    }
}

// MARK: - Previews

struct MainButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(MainButton.Style.allCases, id: \.hashValue) { style in
                buttons(style: style)
                    .previewDisplayName(style.rawValue)
            }
        }
        .previewLayout(.sizeThatFits)
    }

    @ViewBuilder
    static func buttons(style: MainButton.Style) -> some View {
        VStack(spacing: 16) {
            MainButton(
                title: "Order card",
                icon: .leading(Assets.tangemIcon),
                style: style
            ) {}

            MainButton(
                title: "Order card",
                icon: .leading(Assets.tangemIcon),
                style: style,
                size: .notification,
                isDisabled: true
            ) {}

            MainButton(
                title: "Order card",
                icon: .trailing(Assets.tangemIcon),
                style: style
            ) {}

            MainButton(
                title: "Order card",
                icon: .trailing(Assets.tangemIcon),
                style: style,
                isDisabled: true
            ) {}

            MainButton(
                title: "Order card",
                icon: .trailing(Assets.tangemIcon),
                style: style,
                size: .notification,
                isLoading: true
            ) {}

            MainButton(
                title: "A long long long long long long long long long long text",
                icon: .trailing(Assets.tangemIcon),
                style: style,
                isLoading: false
            ) {}

            HStack {
                MainButton(
                    title: "Order card",
                    icon: .leading(Assets.tangemIcon),
                    style: style
                ) {}

                MainButton(
                    title: "Order card",
                    icon: .leading(Assets.tangemIcon),
                    style: style,
                    size: .notification
                ) {}
            }

            Group {
                MainButton(
                    title: "Do something",
                    style: style
                ) {}

                MainButton(
                    title: "Do something else",
                    subtitle: "Or don't do it at all",
                    style: style
                ) {}

                MainButton(
                    title: "Order card",
                    subtitle: "Blahblah",
                    icon: .leading(Assets.tangemIcon),
                    style: style
                ) {}

                MainButton(
                    title: "Order card",
                    subtitle: "Blahblah blahblah blahblah blahblah blahblah blahblah blahblah blahblah blahblah blahblah",
                    icon: .trailing(Assets.tangemIcon),
                    style: style
                ) {}
            }
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.secondary)
    }
}
