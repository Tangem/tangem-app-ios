//
//  CardsInfoPageHeaderPlaceholderView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// This placeholder must be inserted into `List`/`ScrollView` for vertical scrolling to work.
/// Required when pages in `CardsInfoPagerView` have nested `ScrollView` or `List`
/// See examples in the preview section for `CardsInfoPagerView` (`DummyCardInfoPageView` page view).
struct CardsInfoPageHeaderPlaceholderView: View {
    @Environment(\.cardsInfoPageHeaderPlaceholderHeight) private var headerPlaceholderHeight

    var body: some View {
        Color.clear
            .frame(idealWidth: .infinity)
            .frame(height: headerPlaceholderHeight)
            .listRowInsets(EdgeInsets())
    }
}
