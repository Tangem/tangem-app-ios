//
//  View+DetentBottomSheet.swift
//  Tangem
//
//  Created by skibinalexander on 06.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// - Parameters:
    ///   - item: It'ill be used for create the content
    ///   - detents: Map detents list for any ios version
    ///   - settings: You can setup the sheet's appearance
    ///   - sheetContent: View for `sheetContent`
    @available(iOS 14.0, *)
    @ViewBuilder
    func detentBottomSheet<Item: Identifiable, ContentView: View>(
        item: Binding<Item?>,
        detents: Set<DetentBottomSheetContainer<ContentView>.Detent> = [.large],
        settings: DetentBottomSheetContainer<ContentView>.Settings = .init(),
        @ViewBuilder sheetContent: @escaping (Item) -> ContentView
    ) -> some View {
        modifier(
            DetentBottomSheetModifier(
                item: item,
                detents: detents,
                settings: settings,
                sheetContent: sheetContent
            )
        )
    }
}
