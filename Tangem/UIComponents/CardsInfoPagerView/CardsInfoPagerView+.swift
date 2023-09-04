//
//  CardsInfoPagerView+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience initializers

extension CardsInfoPagerView where BottomOverlay == EmptyView {
    init(
        data: Data,
        id idProvider: KeyPath<(Data.Index, Data.Element), ID>,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.init(
            data: data,
            id: idProvider,
            selectedIndex: selectedIndex,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            bottomOverlayFactory: { _ in EmptyView() },
            onPullToRefresh: onPullToRefresh
        )
    }
}

extension CardsInfoPagerView where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        data: Data,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        @ViewBuilder bottomOverlayFactory: @escaping BottomOverlayFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.init(
            data: data,
            id: \.1.id,
            selectedIndex: selectedIndex,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            bottomOverlayFactory: bottomOverlayFactory,
            onPullToRefresh: onPullToRefresh
        )
    }
}

extension CardsInfoPagerView where Data.Element: Identifiable, Data.Element.ID == ID, BottomOverlay == EmptyView {
    init(
        data: Data,
        selectedIndex: Binding<Int>,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        onPullToRefresh: OnPullToRefresh? = nil
    ) {
        self.init(
            data: data,
            id: \.1.id,
            selectedIndex: selectedIndex,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            bottomOverlayFactory: { _ in EmptyView() },
            onPullToRefresh: onPullToRefresh
        )
    }
}
