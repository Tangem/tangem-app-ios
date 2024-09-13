//
//  View+AdaptiveSizeSheetModifier.swift
//  Tangem
//
//  Created by GuitarKitty on 13.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct AdaptiveSizeSheetModifier: ViewModifier {
    @State private var height: CGFloat = 0

    private var scrollViewAxis: Axis.Set {
        height >= screenHeight ? .vertical : []
    }

    private var scrollableContentBottomPadding: CGFloat {
        height >= screenHeight ? defaultBottomPadding : 0
    }

    private let screenHeight = UIScreen.main.bounds.height
    private let defaultBottomPadding: CGFloat = 20
    private let cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        scrollableSheetContnet {
            VStack(spacing: 0) {
                GrabberViewFactory()
                    .makeSwiftUIView()
                content
            }
        }
    }

    private func scrollableSheetContnet<Body: View>(content: () -> Body) -> some View {
        ScrollView(scrollViewAxis, showsIndicators: false) {
            content()
                .padding(.bottom, defaultBottomPadding)
                .presentationDetents([.height(height)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadiusBackport(cornerRadius)
                .readGeometry(\.size.height) {
                    height = $0
                }
                .padding(.bottom, scrollableContentBottomPadding)
        }
    }
}

@available(iOS 16.0, *)
extension View {
    func adaptivePresentationDetents() -> some View {
        modifier(AdaptiveSizeSheetModifier())
    }
}

@available(iOS 16.0, *)
private extension View {
    @ViewBuilder
    func presentationCornerRadiusBackport(_ cornerRadius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(cornerRadius)
        } else {
            self
        }
    }
}
