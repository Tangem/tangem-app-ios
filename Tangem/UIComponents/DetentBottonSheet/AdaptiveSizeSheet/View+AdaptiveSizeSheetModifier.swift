//
//  View+AdaptiveSizeSheetModifier.swift
//  Tangem
//
//  Created by GuitarKitty on 13.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSwiftUIUtils

struct AdaptiveSizeSheetModifier: ViewModifier {
    @StateObject private var viewModel = AdaptiveSizeSheetViewModel()
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            handler

            scrollableSheetContent(content: content)
        }
    }

    private var handler: some View {
        Color.clear
            .frame(height: viewModel.handleHeight)
            .overlay(alignment: .top) {
                GrabberViewFactory()
                    .makeSwiftUIView()
            }
    }

    private func scrollableSheetContent(content: Content) -> some View {
        ScrollView(viewModel.scrollViewAxis, showsIndicators: false) {
            content
                .padding(.bottom, viewModel.defaultBottomPadding)
                .presentationDetents(contentHeight: viewModel.contentHeight, cornerRadius: viewModel.cornerRadius)
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

private extension View {
    @ViewBuilder
    func presentationDetents(contentHeight: CGFloat, cornerRadius: CGFloat) -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.height(contentHeight)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadiusBackport(cornerRadius)
        } else {
            self
        }
    }
}

@available(iOS 16.0, *)
private extension View {
    @ViewBuilder
    func presentationCornerRadiusBackport(_ cornerRadius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(cornerRadius)
        } else {
            presentationConfiguration { controller in
                controller.preferredCornerRadius = cornerRadius
            }
        }
    }
}

extension View {
    @ViewBuilder
    func adaptivePresentationDetents() -> some View {
        modifier(AdaptiveSizeSheetModifier())
    }
}
