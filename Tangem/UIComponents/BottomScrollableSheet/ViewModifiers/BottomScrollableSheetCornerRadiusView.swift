//
//  BottomScrollableSheetCornerRadiusView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetCornerRadiusView<Content>: View where Content: View {
    let content: Content

    var body: some View {
        content
            .cornerRadius(Constants.cornerRadius, corners: [.topLeft, .topRight])
    }
}

// MARK: - Constants

private extension BottomScrollableSheetCornerRadiusView {
    enum Constants {
        static var cornerRadius: CGFloat { 24.0 }
    }
}

// MARK: - Convenience extensions

extension View {
    func bottomScrollableSheetCornerRadius() -> some View {
        BottomScrollableSheetCornerRadiusView(content: self)
    }
}
