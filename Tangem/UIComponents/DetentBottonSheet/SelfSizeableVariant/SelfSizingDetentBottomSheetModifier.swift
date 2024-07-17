//
//  SelfSizingDetentBottomSheetModifier.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

protocol SelfSizingBottomSheetContent {
    func setContentHeightBinding(_ binding: ContentHeightBinding) -> Self
}

typealias ContentHeightBinding = Binding<CGFloat>
struct SelfSizingDetentBottomSheetModifier<Item: Identifiable, ContentView: View & SelfSizingBottomSheetContent>: ViewModifier {
    @Binding private var item: Item?

    private let detents: Set<BottomSheetDetent>
    private let settings: Settings
    private var sheetContent: (Item) -> ContentView

    init(
        item: Binding<Item?>,
        detents: Set<BottomSheetDetent>,
        settings: Settings,
        sheetContent: @escaping (Item) -> ContentView
    ) {
        _item = item
        self.detents = detents
        self.settings = settings
        self.sheetContent = sheetContent
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            aboveIOS16SheetUpdate(item: item, on: content)
        } else {
            beforeIOS16SheetUpdate(item: item, on: content)
        }
    }
}

// MARK: - Above iOS_16.0 UIKit Implementation BottomSheet

private extension SelfSizingDetentBottomSheetModifier {
    @available(iOS 16.0, *)
    func aboveIOS16SheetUpdate(item: Item?, on content: Content) -> some View {
        content.sheet(item: $item) { item in
            let sheetView = SelfSizingDetentBottomSheetContainer(bottomSheetHeight: settings.contentHeightBinding) { sheetContent(item) }
                .background(settings.backgroundColor)
                .presentationDragIndicator(.hidden)
                .presentationDetents(Set(detents.map { $0.detentsAboveIOS16 }))

            if #available(iOS 16.4, *) {
                sheetView
                    .presentationCornerRadius(settings.cornerRadius)
            } else {
                sheetView
            }
        }
    }
}

// MARK: - Before iOS_16.0 UIKit Implementation BottomSheet

private extension SelfSizingDetentBottomSheetModifier {
    func beforeIOS16SheetUpdate(item: Item?, on content: Content) -> some View {
        content.sheet(item: $item) { item in
            SelfSizingDetentBottomSheetContainer(bottomSheetHeight: settings.contentHeightBinding) {
                sheetContent(item)
            }
            .background(settings.backgroundColor)
            .presentationConfiguration { controller in
                controller.detents = detents.map { $0.detentsBelowIOS16 }
                controller.preferredCornerRadius = settings.cornerRadius
            }
        }
    }
}

// MARK: - Settings

extension SelfSizingDetentBottomSheetModifier {
    struct Settings {
        let cornerRadius: CGFloat
        let backgroundColor: Color?
        let contentHeightBinding: ContentHeightBinding

        init(cornerRadius: CGFloat = 24, backgroundColor: Color? = nil, contentHeightBinding: ContentHeightBinding = .constant(100)) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.contentHeightBinding = contentHeightBinding
        }
    }
}
