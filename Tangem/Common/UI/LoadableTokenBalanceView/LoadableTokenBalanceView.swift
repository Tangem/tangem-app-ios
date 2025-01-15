//
//  LoadableTokenBalanceView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 27.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct LoadableTokenBalanceView: View {
    let state: State
    let style: Style
    let loader: LoaderStyle

    init(state: State, style: Style, loader: LoaderStyle) {
        self.state = state
        self.style = style
        self.loader = loader
    }

    var body: some View {
        switch state {
        case .loading(.some(let cached)):
            textView(cached)
                .modifier(PulseEffect())
        case .loading(.none):
            RoundedRectangle(cornerRadius: loader.cornerRadius, style: .continuous)
                .fill(Colors.Background.tertiary)
                .frame(size: loader.size)
                .modifier(Shimmer())
        case .failed(let text, let withIcon):
            HStack(spacing: 6) {
                if withIcon {
                    Assets.failedCloud.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.inactive)
                        .frame(width: 12, height: 12)
                }

                textView(text)
            }
        case .loaded(let text):
            textView(text)
        }
    }

    private func textView(_ text: Text) -> some View {
        SensitiveText(text)
            .style(style.font, color: style.textColor)
    }
}

extension LoadableTokenBalanceView {
    typealias Text = SensitiveText.TextType

    enum State: Hashable {
        case loading(cached: Text? = nil)
        case failed(cached: Text, withIcon: Bool = false)
        case loaded(text: Text)

        // Convenient

        static let empty: State = .loaded(text: .string(BalanceFormatter.defaultEmptyBalanceString))
        static func loaded(text: String) -> State { .loaded(text: .string(text)) }
    }

    struct Style {
        let font: Font
        let textColor: Color
    }

    struct LoaderStyle {
        let size: CGSize
        let cornerRadius: CGFloat

        init(size: CGSize, cornerRadius: CGFloat = 3) {
            self.size = size
            self.cornerRadius = cornerRadius
        }
    }
}

#Preview {
    let attributed = BalanceFormatter().formatAttributedTotalBalance(
        fiatBalance: "1 312 422,23 $",
        formattingOptions: .defaultOptions
    )

    VStack(alignment: .trailing, spacing: 16) {
        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loading(cached: .attributed(attributed)),
                style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                loader: .init(size: .init(width: 40, height: 12))
            )

            LoadableTokenBalanceView(
                state: .loading(cached: .string("1,23 BTC")),
                style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                loader: .init(size: .init(width: 40, height: 12))
            )
        }

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loading(cached: .string("1 312 422,23 $")),
                style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                loader: .init(size: .init(width: 40, height: 12))
            )

            LoadableTokenBalanceView(
                state: .loading(cached: .string("1,23 BTC")),
                style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                loader: .init(size: .init(width: 40, height: 12))
            )
        }

        Divider()

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loaded(text: .string("1 312 422,23 $")),
                style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                loader: .init(size: .init(width: 40, height: 12))
            )

            LoadableTokenBalanceView(
                state: .loaded(text: .string("1,23 BTC")),
                style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                loader: .init(size: .init(width: 40, height: 12))
            )
        }

        Divider()

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .failed(cached: .string("1 312 422,23 $"), withIcon: true),
                style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                loader: .init(size: .init(width: 40, height: 12))
            )

            LoadableTokenBalanceView(
                state: .failed(cached: .string("1,23 BTC")),
                style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                loader: .init(size: .init(width: 40, height: 12))
            )
        }
    }
    .padding()
}
