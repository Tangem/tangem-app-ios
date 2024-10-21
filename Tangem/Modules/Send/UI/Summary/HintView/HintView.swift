//
//  HintView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct HintView: View {
    let text: String
    let font: Font
    let textColor: Color
    let backgroundColor: Color

    private let cornerRadius: CGFloat = 14
    private let arrowSize = CGSize(width: 24, height: 9)

    var body: some View {
        VStack(spacing: 0) {
            TriangleShape()
                .fill(backgroundColor)
                .frame(width: arrowSize.width, height: arrowSize.height)

            Text(text)
                .style(font, color: textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                )
        }
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ]

        var path = Path()
        path.addLines(points)
        return path
    }
}

#Preview {
    HintView(
        text: "Tap any field to change it",
        font: .body,
        textColor: .white,
        backgroundColor: .red
    )
}
