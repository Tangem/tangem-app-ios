//
//  MainButton.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainButton: View {
    private let text: String
    private let icon: Icon?
    private let style: Style
    private let action: () -> Void
    private let isDisabled: Bool

    init(
        text: String,
        icon: Icon? = nil,
        style: Style = .primary,
        action: @escaping (() -> Void),
        isDisabled: Bool = false
    ) {
        self.text = text
        self.icon = icon
        self.style = style
        self.action = action
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                .background(style.background(isDisabled: isDisabled))
                .cornerRadius(14)
                .contentShape(Rectangle())
        }
        .disabled(isDisabled)
    }

    @ViewBuilder
    private var content: some View {
        switch icon {
        case .none:
            textView

        case let .leading(icon):
            HStack(alignment: .center, spacing: 10) {
                iconView(icon: icon)

                textView
            }
        case let .trailing(icon):
            HStack(alignment: .center, spacing: 10) {
                textView

                iconView(icon: icon)
            }
        }
    }

    @ViewBuilder
    private var textView: some View {
        Text(text)
            .style(Fonts.Bold.callout,
                   color: style.textColor(isDisabled: isDisabled))
    }

    @ViewBuilder
    private func iconView(icon: Image) -> some View {
        icon
            .resizable()
            .renderingMode(.template)
            .frame(width: 20, height: 20)
            .foregroundColor(style.iconColor(isDisabled: isDisabled))
    }
}

extension MainButton {
    enum Icon {
        case leading(_ icon: Image)
        case trailing(_ icon: Image)
    }

    enum Style: String, Hashable, CaseIterable {
        case primary
        case secondary

        func iconColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Icon.inactive
            }

            switch self {
            case .primary:
                return Colors.Icon.primary2
            case .secondary:
                return Colors.Icon.primary1
            }
        }

        func textColor(isDisabled: Bool) -> Color {
            if isDisabled {
                return Colors.Text.disabled
            }

            switch self {
            case .primary:
                return Colors.Text.primary2
            case .secondary:
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
            }
        }
    }
}

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
            MainButton(text: "Order card",
                       icon: .leading(Assets.tangemIcon),
                       style: style,
                       action: {})

            MainButton(text: "Order card",
                       icon: .leading(Assets.tangemIcon),
                       style: style,
                       action: {},
                       isDisabled: true)

            MainButton(text: "Order card",
                       icon: .trailing(Assets.tangemIcon),
                       style: style,
                       action: {})

            MainButton(text: "Order card",
                       icon: .trailing(Assets.tangemIcon),
                       style: style,
                       action: {},
                       isDisabled: true)
        }
        .padding(.horizontal, 16)
    }
}
