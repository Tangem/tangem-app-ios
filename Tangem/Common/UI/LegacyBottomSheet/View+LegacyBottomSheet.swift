//
//  View+LegacyBottomSheet.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 18.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @available(*, deprecated, message: "Use bottomSheet method with BottomSheetModifier")
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        viewModelSettings: BottomSheetSettings,
        @ViewBuilder contentView: @escaping () -> Content
    ) -> some View {
        modifier(LegacyBottomSheetModifier(isPresented: isPresented, viewModelSettings: viewModelSettings, contentView: contentView))
    }

    @available(*, deprecated, message: "Use bottomSheet method with BottomSheetModifier")
    func bottomSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        viewModelSettings: BottomSheetSettings,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        let isPresented = Binding {
            item.wrappedValue != nil
        } set: { value in
            if !value {
                item.wrappedValue = nil
            }
        }

        return bottomSheet(isPresented: isPresented, viewModelSettings: viewModelSettings) {
            if let unwrapedItem = item.wrappedValue {
                content(unwrapedItem)
            } else {
                EmptyView()
            }
        }
    }
}
