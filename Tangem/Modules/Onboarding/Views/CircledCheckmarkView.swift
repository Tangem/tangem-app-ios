//
//  CircledCheckmarkView.swift
//  Tangem
//
//  Created by Andrew Son on 04/08/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct CircledCheckmarkView: View {
    var borderColor: Color = .white
    var foregroundColor: Color = Colors.Icon.accent
    var filled: Bool

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .strokeBorder(borderColor, lineWidth: 2)
                .background(Circle().foregroundColor(foregroundColor))
                .opacity(filled ? 1.0 : 0.0)
            Checkmark(filled: filled)
        }
    }
}

struct Checkmark: View {
    var lineWidth: CGFloat = 1.5
    var filled: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Path { path in
                path.move(to: CGPoint(x: size.width / 2 - size.width / 6, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width / 2 - size.width / 20, y: size.height / 2 + size.height / 10))
                path.addLine(to: CGPoint(x: size.width / 2 + size.width / 5, y: size.height / 2 - size.height / 6))
            }
            .trim(from: 0, to: filled ? 1.0 : 0.0)
            .stroke(Color.white, lineWidth: lineWidth)
        }
    }
}

struct CircledCheckmarkView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            CircledCheckmarkView(filled: true)
                .frame(size: CGSize(width: 60, height: 60))
        }
    }
}
