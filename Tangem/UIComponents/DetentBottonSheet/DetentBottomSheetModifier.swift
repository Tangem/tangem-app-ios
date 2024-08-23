//
//  DetentBottomSheetModifier.swift
//  Tangem
//
//  Created by skibinalexander on 05.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct DetentBottomSheetModifier<Item: Identifiable, ContentView: View>: ViewModifier {
    typealias Sheet = DetentBottomSheetContainer<ContentView>

    @Binding private var item: Item?

    private let detents: Set<BottomSheetDetent>
    private let settings: Sheet.Settings
    private var sheetContent: (Item) -> ContentView

    init(
        item: Binding<Item?>,
        detents: Set<BottomSheetDetent>,
        settings: Sheet.Settings,
        sheetContent: @escaping (Item) -> ContentView
    ) {
        _item = item
        self.detents = detents
        self.settings = settings
        self.sheetContent = sheetContent
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            aboveIOS16SheetUpdate(item: item, on: content)
        } else {
            beforeIOS16SheetUpdate(item: item, on: content)
        }
    }
}

// MARK: - Above iOS_16.4 UIKit Implementation BottomSheet

@available(iOS 16.4, *)
private extension DetentBottomSheetModifier {
    func aboveIOS16SheetUpdate(item: Item?, on content: Content) -> some View {
        content
            .sheet(item: $item) { item in
                DetentBottomSheetContainer {
                    sheetContent(item)
                }
                .background(settings.background)
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(settings.cornerRadius)
                .presentationDetents(detents.map { $0.detentsAboveIOS16 }.toSet())
            }
    }
}

// MARK: - Before iOS_16.4 UIKit Implementation BottomSheet

private extension DetentBottomSheetModifier {
    func beforeIOS16SheetUpdate(item: Item?, on content: Content) -> some View {
        content
            .sheet(item: $item) { item in
                DetentBottomSheetContainer {
                    sheetContent(item)
                }
                .background(settings.background)
                .presentationConfiguration { controller in
                    controller.detents = detents.map { $0.detentsBelowIOS16 }
                    controller.preferredCornerRadius = settings.cornerRadius
                }
            }
    }
}
