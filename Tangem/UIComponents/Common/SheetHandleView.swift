//
//  SheetHandleView.swift
//  Tangem
//
//  Created by Andrew Son on 25/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct SheetHandleView: View {
    let backgroundColor: Color

    private let indicatorSize = CGSize(width: 32, height: 4)

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: indicatorSize)
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }
}

#Preview {
    VStack(spacing: 20) {
        SheetHandleView(backgroundColor: Colors.Background.primary)

        SheetHandleView(backgroundColor: Colors.Background.secondary)
    }
}
