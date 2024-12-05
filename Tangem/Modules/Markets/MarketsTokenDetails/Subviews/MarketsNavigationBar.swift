//
//  MarketsNavigationBar.swift
//  Tangem
//
//  Created by Andrew Son on 08.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsNavigationBar<Content: View>: View {
    let titleView: () -> Content
    let onBackButtonAction: () -> Void

    init(titleView: @escaping () -> Content, onBackButtonAction: @escaping () -> Void) {
        self.titleView = titleView
        self.onBackButtonAction = onBackButtonAction
    }

    var body: some View {
        NavigationBar(
            settings: .init(
                backgroundColor: .clear, // Controlled by the `background` modifier in the body
                height: 64.0,
                alignment: .bottom
            ),
            titleView: titleView,
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

extension MarketsNavigationBar where Content == DefaultNavigationBarTitle {
    init(title: String, onBackButtonAction: @escaping () -> Void) {
        titleView = {
            DefaultNavigationBarTitle(
                title: title,
                settings: .init(
                    font: Fonts.Bold.body,
                    color: Colors.Text.primary1,
                    lineLimit: 1,
                    minimumScaleFactor: 0.6
                )
            )
        }
        self.onBackButtonAction = onBackButtonAction
    }
}

// #Preview {
//    MarketsNavigationBar(
//        isMarketsSheetStyle: true,
//        title: "Exchanges",
//        onBackButtonAction: {}
//    )
// }
