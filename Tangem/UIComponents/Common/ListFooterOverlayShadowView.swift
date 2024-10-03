//
//  ListFooterOverlayShadowView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ListFooterOverlayShadowView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Colors.Background.primary.opacity(0.0),
                Colors.Background.primary.opacity(0.95),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .bottom)
    }
}
