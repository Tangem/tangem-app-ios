//
//  DefaultFooterView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultFooterView: View {
    private let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            // We've calculation height problem here
            // SUI BottomSheet can't do it normally without this `fixedSize`
            .fixedSize(horizontal: false, vertical: true)
    }
}
