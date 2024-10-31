//
//  MainBottomSheetFooterShadowView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MainBottomSheetFooterShadowView: View {
    let colorScheme: ColorScheme
    let shadowColor: Color

    private var startColor: Color {
        return shadowColor.opacity(0.0)
    }

    private var endColor: Color {
        return shadowColor.opacity(colorScheme == .dark ? 0.36 : 0.08)
    }

    var body: some View {
        LinearGradient(
            colors: [
                startColor,
                endColor,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 69.0)
        .offset(y: -42.0)
        .allowsHitTesting(false)
    }
}
