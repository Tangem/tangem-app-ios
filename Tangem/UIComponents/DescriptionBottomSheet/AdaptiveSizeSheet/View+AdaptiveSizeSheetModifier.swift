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
    @StateObject private var viewModel = AdaptiveSizeSheetViewModel()

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
        ScrollView(viewModel.scrollViewAxis, showsIndicators: false) {
            content()
                .padding(.bottom, viewModel.defaultBottomPadding)
                .presentationDetents([.height(viewModel.contentHeight)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadiusBackport(viewModel.cornerRadius)
                .readGeometry(\.size.height) {
                    viewModel.contentHeight = $0
                }
                .padding(.bottom, viewModel.scrollableContentBottomPadding)
        }
        .readGeometry(\.size.height) {
            viewModel.containerHeight = $0
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
