//
//  CloseButton.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct CloseButton: View {
    let dismiss: () -> Void

    var body: some View {
        Button(
            action: dismiss,
            label: {
                Text(Localization.commonClose)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            }
        )
    }
}
