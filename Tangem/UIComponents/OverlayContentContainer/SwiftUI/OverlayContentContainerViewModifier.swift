//
//  OverlayContentContainerViewModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

extension View {
    func overlayContentContainer<Item, Overlay>(
        item: Binding<Item?>,
        @ViewBuilder overlayFactory: @escaping (_ item: Item) -> Overlay
    ) -> some View where Item: Identifiable, Overlay: View {
        modifier(
            OverlayContentContainerViewModifier(item: item, overlayFactory: overlayFactory)
        )
    }
}

// MARK: - Private implementation

private struct OverlayContentContainerViewModifier<
    Item, Overlay
>: ViewModifier where Item: Identifiable, Overlay: View {
    private let overlayFactory: (_ item: Item) -> Overlay

    @Binding private var item: Item?

    @available(iOS, deprecated: 17.0, message: "Not needed if `View.onChange(of:initial:_:)` is available (iOS 17+)")
    @State private var isAppeared = false

    @Environment(\.overlayContentContainer) private var overlayContentContainer
    @Environment(\.overlayContentStateObserver) private var overlayContentStateObserver
    @Environment(\.overlayContentStateController) private var overlayContentStateController

    init(
        item: Binding<Item?>,
        overlayFactory: @escaping (_ item: Item) -> Overlay
    ) {
        _item = item
        self.overlayFactory = overlayFactory
    }

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: item?.id, initial: true) {
                    updateOverlay()
                }
        } else {
            content
                .onChange(of: item?.id) { _ in
                    updateOverlay()
                }
                .onAppear {
                    guard !isAppeared else {
                        return
                    }

                    /// Prevents warnings like "Modifying state during view update, this will cause undefined behavior."
                    DispatchQueue.main.async {
                        isAppeared = true
                    }

                    updateOverlay()
                }
        }
    }

    private func updateOverlay() {
        // Always removing previous overlay since this is a requirement of `OverlayContentContainerViewController`' API
        overlayContentContainer.removeOverlay()

        if let item {
            // `overlay` is a completely different branch of the SwiftUI view hierarchy,
            // so we must explicitly re-inject `overlayContentContainer`, `overlayContentStateObserver`
            // and `overlayContentStateController` environment objects into this branch
            let overlay = overlayFactory(item)
                .environment(\.overlayContentContainer, overlayContentContainer)
                .environment(\.overlayContentStateObserver, overlayContentStateObserver)
                .environment(\.overlayContentStateController, overlayContentStateController)

            overlayContentContainer.installOverlay(overlay)
        }
    }
}
