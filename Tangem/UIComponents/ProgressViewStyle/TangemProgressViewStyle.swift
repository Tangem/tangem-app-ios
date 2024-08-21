//
//  TangemProgressViewStyle.swift
//  Tangem
//
//  Created by Andrew Son on 11/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemProgressViewStyle: ProgressViewStyle {
    var height: CGFloat
    var backgroundColor: Color
    var progressColor: Color
    var cornerRadius: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        let cornerRadius = cornerRadius ?? (height / 2)
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(progressColor)
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, height: height)
            }
        }
        .frame(height: height)
    }
}
