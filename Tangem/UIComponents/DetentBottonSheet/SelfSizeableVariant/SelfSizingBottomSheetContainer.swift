//
//  SelfSizingBottomSheetContainer.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct SelfSizingDetentBottomSheetContainer<ContentView: View & SelfSizingBottomSheetContent>: View {
    @Environment(\.mainWindowSize) private var mainWindowSize: CGSize

    /// Binding to update detent height to fit content
    @Binding var bottomSheetHeight: CGFloat
    @State private var contentHeight: CGFloat = 0
    /// We need to know container height to be able to decide is content bigger than available space
    /// If so put content inside `ScrollView`
    @State private var containerHeight: CGFloat = 0

    let content: () -> ContentView

    private let handleHeight: CGFloat = 20
    private let indicatorSize = CGSize(width: 32, height: 4)
    private let defaultBottomPadding: CGFloat = 16
    private let scrollViewBottomOffset: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Capsule(style: .continuous)
                    .fill(Colors.Icon.inactive)
                    .frame(size: indicatorSize)
            }
            .frame(height: handleHeight, alignment: .center)

            sheetContent
                .frame(minWidth: mainWindowSize.width)
        }
        .frame(alignment: .top) // TODO: Remove this frame when migrate increase min iOS to 16.
        .ignoresSafeArea(edges: .bottom)
        .readGeometry(onChange: { geometry in
            containerHeight = geometry.size.height
        })
        .onChange(of: contentHeight, perform: { value in
            bottomSheetHeight = value + handleHeight
        })
    }

    private var sheetContent: some View {
        let content = content()
            .setContentHeightBinding($contentHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        return Group {
            if containerHeight < bottomSheetHeight {
                ScrollView(showsIndicators: false) {
                    content
                        .padding(.bottom, scrollViewBottomOffset)
                }
            } else {
                content
            }
        }
    }
}
