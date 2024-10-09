//
//  MarketsNavigationBar.swift
//  Tangem
//
//  Created by Andrew Son on 08.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsNavigationBar: View {
    let isMarketsSheetStyle: Bool
    let title: String
    let onBackButtonAction: () -> Void

    var body: some View {
        if isMarketsSheetStyle {
            NavigationBar(
                title: title,
                settings: .init(
                    title: .init(
                        font: Fonts.Bold.body,
                        color: Colors.Text.primary1,
                        lineLimit: 1,
                        minimumScaleFactor: 0.6
                    ),
                    backgroundColor: .clear, // Controlled by the `background` modifier in the body
                    height: 64.0,
                    alignment: .bottom
                ),
                leftButtons: {
                    BackButton(
                        height: 44.0,
                        isVisible: true,
                        isEnabled: true,
                        hPadding: 10.0,
                        action: onBackButtonAction
                    )
                }
            )
        }
    }
}

#Preview {
    MarketsNavigationBar(
        isMarketsSheetStyle: true,
        title: "Exchanges",
        onBackButtonAction: {}
    )
}
