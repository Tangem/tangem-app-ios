//
//  BottomScrollableSheetModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetModifier<SheetHeader, SheetContent>: ViewModifier where SheetHeader: View, SheetContent: View {
    let isHiddenWhenCollapsed: Bool
    let prefersGrabberVisible: Bool
    let allowsHitTesting: Bool

    @ViewBuilder let sheetHeader: () -> SheetHeader
    @ViewBuilder let sheetContent: () -> SheetContent

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
                content: sheetContent
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
    func bottomScrollableSheet<Header, Content>(
        isHiddenWhenCollapsed: Bool = false,
        prefersGrabberVisible: Bool = true,
        allowsHitTesting: Bool = true,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Header: View, Content: View {
        modifier(
            BottomScrollableSheetModifier(
                isHiddenWhenCollapsed: isHiddenWhenCollapsed,
                prefersGrabberVisible: prefersGrabberVisible,
                allowsHitTesting: allowsHitTesting,
                sheetHeader: header,
                sheetContent: content
            )
        )
    }
}
