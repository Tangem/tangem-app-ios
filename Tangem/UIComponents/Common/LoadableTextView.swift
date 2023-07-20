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
    /// Use this to adjust loader position in vertical direction to prevent jumping behaviour
    /// when view changes state from `loading` to `loaded`
    var loaderTopPadding: CGFloat = 0.0

    var lineLimit: Int = 1

    var body: some View {
        switch state {
        case .initialized:
            Text(" ")
                .frame(size: loaderSize)
        case .noData:
            Text("–")
                .style(font, color: textColor)
                .frame(minHeight: loaderSize.height)
        case .loading:
            SkeletonView()
                .frame(size: loaderSize)
                .cornerRadiusContinuous(loaderCornerRadius)
                .padding(.top, loaderTopPadding)
        case .loaded(let text):
            Text(text)
                .style(font, color: textColor)
                .lineLimit(lineLimit)
                .frame(minHeight: loaderSize.height)
        }
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
            ForEach(states.indexed(), id: \.1.1) { index, state in
                LoadableTextView(
                    state: state.0,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 100, height: 20),
                    loaderTopPadding: (index == states.count - 1) ? 0.0 : 4.0
                )
            }
        }
    }
}
