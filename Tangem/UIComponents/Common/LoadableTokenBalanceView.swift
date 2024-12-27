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
    let font: Font
    let textColor: Color
    let loaderSize: CGSize

    var body: some View {
        switch state {
        case .loading(.some(let cached)):
            SensitiveText(cached)
                .style(font, color: textColor)
                .pulseEffect()
        case .loading(.none):
            SkeletonView()
                .frame(size: loaderSize)
                .cornerRadiusContinuous(3)
        case .failed(let text, true):
            HStack(spacing: 6) {
                Assets.failedCloud.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.inactive)
                    .frame(width: 12, height: 12)

                SensitiveText(text)
                    .style(font, color: textColor)
            }
        case .failed(let text, false):
            SensitiveText(text)
                .style(font, color: textColor)
        case .loaded(let text):
            SensitiveText(text)
                .style(font, color: textColor)
        }
    }
}

extension LoadableTokenBalanceView {
    typealias Text = SensitiveText.TextType

    enum State {
        case loading(cached: Text?)
        case failed(cached: Text, withIcon: Bool = false)
        case loaded(text: Text)
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: 16) {
        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loading(cached: .string("1 312 422,23 $")),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .loading(cached: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }

        Divider()

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .loaded(text: .string("1 312 422,23 $")),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .loaded(text: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }

        Divider()

        VStack(alignment: .trailing, spacing: 2) {
            LoadableTokenBalanceView(
                state: .failed(cached: .string("1 312 422,23 $"), withIcon: true),
                font: Fonts.Regular.subheadline,
                textColor: Colors.Text.primary1,
                loaderSize: .init(width: 40, height: 12)
            )

            LoadableTokenBalanceView(
                state: .failed(cached: .string("1,23 BTC")),
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: .init(width: 40, height: 12)
            )
        }
    }
    .padding()
}
