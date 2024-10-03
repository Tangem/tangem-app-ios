//
//  LoadableTextView.swift
//  Tangem
//
//  Created by Andrew Son on 28/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LoadableTextView: View {
    let state: State
    let font: Font
    let textColor: Color
    let loaderSize: CGSize
    var loaderCornerRadius: CGFloat = 3.0

    var prefix: String? = nil
    var lineLimit: Int = 1
    var isSensitiveText: Bool = false

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .initialized:
            styledDashText
                .opacity(0.01)
        case .noData:
            styledDashText
        case .loading:
            ZStack {
                styledDashText
                    .opacity(0.01)
                SkeletonView()
                    .frame(size: loaderSize)
                    .cornerRadiusContinuous(loaderCornerRadius)
            }
        case .loaded(let text):
            if let prefix {
                styledText("\(prefix)\(AppConstants.unbreakableSpace)\(text)", isSensitive: isSensitiveText)
            } else {
                styledText(text, isSensitive: isSensitiveText)
            }
        }
    }

    private var styledDashText: some View {
        styledText("–", isSensitive: false)
    }

    @ViewBuilder
    private func styledText(_ text: String, isSensitive: Bool) -> some View {
        Group {
            if isSensitive {
                SensitiveText(text)
            } else {
                Text(text)
            }
        }
        .style(font, color: textColor)
        .lineLimit(lineLimit)
    }
}

extension LoadableTextView {
    enum State: Hashable {
        case initialized
        case noData
        case loading
        case loaded(text: String)
    }
}

struct LoadableTextView_Preview: PreviewProvider {
    static let states: [(LoadableTextView.State, UUID)] = [
        (.initialized, UUID()),
        (.noData, UUID()),
        (.loading, UUID()),
        (.loaded(text: "Some random text"), UUID()),
        (.loading, UUID()),
    ]

    static var previews: some View {
        VStack {
            HStack(spacing: 0) {
                LoadableTextView(
                    state: .loading,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 40, height: 12)
                )

                LoadableTextView(
                    state: .loaded(text: "0.21432543264 ETH"),
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 40, height: 12)
                )
            }
            ForEach(states.indexed(), id: \.1.1) { index, state in
                LoadableTextView(
                    state: state.0,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 100, height: 20)
                )
            }
        }
    }
}
