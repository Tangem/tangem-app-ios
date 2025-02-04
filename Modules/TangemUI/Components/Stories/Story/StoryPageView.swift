//
//  StoryPageView.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct StoryPageView: View {
    private let screenBounds = UIScreen.main.bounds

    let content: AnyView

    init(content: any View) {
        self.content = AnyView(content)
    }

    var body: some View {
        content
            .frame(maxWidth: screenBounds.width, maxHeight: screenBounds.height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
    }
}
