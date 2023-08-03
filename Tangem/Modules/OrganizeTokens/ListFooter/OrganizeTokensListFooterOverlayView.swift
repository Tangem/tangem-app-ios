//
//  OrganizeTokensListFooterOverlayView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 21.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListFooterOverlayView: View {
    var body: some View {
        LinearGradient(
            colors: [Colors.Background.fadeStart, Colors.Background.fadeEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .infinityFrame(alignment: .top)
        .ignoresSafeArea(edges: .bottom)
    }
}
