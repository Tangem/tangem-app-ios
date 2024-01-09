//
//  BottomScrollableSheetModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetModifier<
    SheetHeader,
    SheetContent,
    SheetOverlay
>: ViewModifier where SheetHeader: View, SheetContent: View, SheetOverlay: View {
    @ViewBuilder let sheetHeader: () -> SheetHeader
    @ViewBuilder let sheetContent: () -> SheetContent
    @ViewBuilder let sheetOverlay: () -> SheetOverlay

    @StateObject private var stateObject = BottomScrollableSheetStateObject()

    @Environment(\.bottomScrollableSheetConfiguration) private var configuration

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
                .cornerRadius(14.0)
                .scaleEffect(stateObject.scale, anchor: .bottom)
                .edgesIgnoringSafeArea(.all)

            BottomScrollableSheet(
                stateObject: stateObject,
                header: sheetHeader,
                content: sheetContent,
                overlay: sheetOverlay
            )
            .prefersGrabberVisible(configuration.prefersGrabberVisible)
            .isHiddenWhenCollapsed(configuration.isHiddenWhenCollapsed)
            .allowsHitTesting(configuration.allowsHitTesting)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Convenience extensions

extension View {
    /// An overload that supports `overlay` view
    func bottomScrollableSheet<Header, Content, Overlay>(
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) -> some View where Header: View, Content: View, Overlay: View {
        modifier(
            BottomScrollableSheetModifier(
                sheetHeader: header,
                sheetContent: content,
                sheetOverlay: overlay
            )
        )
    }

    /// An overload without `overlay` view support.
    func bottomScrollableSheet<Header, Content>(
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Header: View, Content: View {
        return bottomScrollableSheet(
            header: header,
            content: content,
            overlay: { EmptyView() }
        )
    }
}
