//
//  BottomScrollableSheetShadowView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetShadowView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Constants.shadowColor.opacity(0.0),
                Constants.shadowColor.opacity(0.04),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 69.0)
        .offset(y: -39.0)
        .allowsHitTesting(false)
    }
}

// MARK: - Constants

private extension BottomScrollableSheetShadowView {
    enum Constants {
        static let shadowColor: Color = .black
    }
}

// MARK: - Convenience extensions

extension View {
    func bottomScrollableSheetShadow() -> some View {
        background(BottomScrollableSheetShadowView(), alignment: .top)
    }
}
