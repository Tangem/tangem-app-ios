//
//  View+SelfSizingDetentBottomSheet.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// - Parameters:
    ///   - item: It'ill be used for create the content
    ///   - detents: Map detents list for any ios version
    ///   - settings: You can setup the sheet's appearance
    ///   - sheetContent: View for `sheetContent`
    @ViewBuilder
    func selfSizingDetentBottomSheet<Item: Identifiable, ContentView: SelfSizingBottomSheetContent>(
        item: Binding<Item?>,
        detents: Set<BottomSheetDetent> = [.large],
        settings: SelfSizingDetentBottomSheetModifier<Item, ContentView>.Settings = .init(),
        @ViewBuilder sheetContent: @escaping (Item) -> ContentView
    ) -> some View {
        modifier(
            SelfSizingDetentBottomSheetModifier(
                item: item,
                detents: detents,
                settings: settings,
                sheetContent: sheetContent
            )
        )
    }
}
