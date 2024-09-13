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
    private let defaultBottomPadding: CGFloat = 16
    private let scrollViewBottomOffset: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: handleHeight)
                .overlay(alignment: .top) {
                    GrabberViewFactory()
                        .makeSwiftUIView()
                }

            sheetContent
                .frame(minWidth: mainWindowSize.width)
        }
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
        let scrollDisabled = bottomSheetHeight <= containerHeight

        return Group {
            if #available(iOS 16.0, *) {
                ScrollView(.vertical, showsIndicators: false) {
                    content
                        .padding(.bottom, scrollViewBottomOffset)
                }
                .scrollDisabled(scrollDisabled)
            } else {
                ScrollView(scrollDisabled ? [] : .vertical, showsIndicators: false) {
                    content
                        .padding(.bottom, scrollViewBottomOffset)
                }
            }
        }
    }
}
