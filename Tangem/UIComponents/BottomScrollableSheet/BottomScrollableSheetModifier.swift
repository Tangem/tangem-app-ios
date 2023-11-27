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
    let isHiddenWhenCollapsed: Bool
    let prefersGrabberVisible: Bool
    let allowsHitTesting: Bool

    @ViewBuilder let sheetHeader: () -> SheetHeader
    @ViewBuilder let sheetContent: () -> SheetContent
    @ViewBuilder let sheetOverlay: () -> SheetOverlay

    @StateObject private var stateObject = BottomScrollableSheetStateObject()

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
            .prefersGrabberVisible(prefersGrabberVisible)
            .isHiddenWhenCollapsed(isHiddenWhenCollapsed)
            .allowsHitTesting(allowsHitTesting)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Convenience extensions

extension View {
    /// An overload that supports `overlay` view
    func bottomScrollableSheet<Header, Content, Overlay>(
        isHiddenWhenCollapsed: Bool = false,
        prefersGrabberVisible: Bool = true,
        allowsHitTesting: Bool = true,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) -> some View where Header: View, Content: View, Overlay: View {
        modifier(
            BottomScrollableSheetModifier(
                isHiddenWhenCollapsed: isHiddenWhenCollapsed,
                prefersGrabberVisible: prefersGrabberVisible,
                allowsHitTesting: allowsHitTesting,
                sheetHeader: header,
                sheetContent: content,
                sheetOverlay: overlay
            )
        )
    }

    /// An overload without `overlay` view support.
    func bottomScrollableSheet<Header, Content>(
        isHiddenWhenCollapsed: Bool = false,
        prefersGrabberVisible: Bool = true,
        allowsHitTesting: Bool = true,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Header: View, Content: View {
        return bottomScrollableSheet(
            isHiddenWhenCollapsed: isHiddenWhenCollapsed,
            prefersGrabberVisible: prefersGrabberVisible,
            allowsHitTesting: allowsHitTesting,
            header: header,
            content: content,
            overlay: { EmptyView() }
        )
    }
}
