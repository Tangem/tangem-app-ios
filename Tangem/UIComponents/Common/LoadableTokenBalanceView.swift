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
            // New animation
            SensitiveText(cached)
                .style(font, color: textColor)
                .pulseEffect()
        case .loading(.none):
            SkeletonView()
                .frame(size: loaderSize)
                .cornerRadiusContinuous(3)
        case .failed(let text):
            SensitiveText(text)
                .style(font, color: textColor)
        case .loaded(let text):
            SensitiveText(text)
                .style(font, color: textColor)
        }
    }
}

extension LoadableTokenBalanceView {
    enum State {
        case loading(cached: String?)
        case failed(cached: String)
        case loaded(text: String)
    }
}

#Preview {
    LoadableTokenBalanceView(
        state: .loading(cached: nil),
        font: Fonts.Regular.subheadline,
        textColor: Colors.Text.primary1,
        loaderSize: .init(width: 40, height: 12)
    )

    LoadableTokenBalanceView(
        state: .loading(cached: "1,23$"),
        font: Fonts.Regular.subheadline,
        textColor: Colors.Text.primary1,
        loaderSize: .init(width: 40, height: 12)
    )

    LoadableTokenBalanceView(
        state: .failed(cached: "1,23$"),
        font: Fonts.Regular.subheadline,
        textColor: Colors.Text.primary1,
        loaderSize: .init(width: 40, height: 12)
    )

    LoadableTokenBalanceView(
        state: .loaded(text: "1,23$"),
        font: Fonts.Regular.subheadline,
        textColor: Colors.Text.primary1,
        loaderSize: .init(width: 40, height: 12)
    )
}
