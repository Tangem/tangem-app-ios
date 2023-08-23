//
//  ArrowView.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ArrowView: View {
    let position: ItemPosition
    let width: CGFloat
    let height: CGFloat
    let color = Color(name: "manage_tokens_arrow")
    var body: some View {
        LineShape(position: position)
            .foregroundColor(color)
            .overlay(TriangleShape().fill(color))
            .frame(width: width, height: height)
    }
}

enum ItemPosition: Equatable {
    case first
    case middle
    case last
    case single

    fileprivate var startOffset: CGFloat {
        switch self {
        case .single, .first:
            return 6
        default:
            return 0
        }
    }

    fileprivate var isLast: Bool {
        switch self {
        case .single, .last:
            return true
        default:
            return false
        }
    }

    init(with index: Int, total: Int) {
        if total == 1 {
            self = .single
        } else if index == 0 {
            self = .first
        } else if index == total - 1 {
            self = .last
        } else {
            self = .middle
        }
    }
}

private struct LineShape: Shape {
    let position: ItemPosition

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let style = StrokeStyle(
            lineWidth: 1.4,
            lineCap: .round,
            lineJoin: .bevel,
            miterLimit: 0.0,
            dash: [],
            dashPhase: 0.0
        )

        let startPoint = CGPoint(x: rect.midX, y: rect.minY - position.startOffset)
        let startCurvePoint = CGPoint(x: rect.midX, y: rect.minY)
        let endCurvePoint = CGPoint(x: rect.maxX, y: rect.midY)
        let bottomPoint = position.isLast ? startCurvePoint : CGPoint(x: rect.midX, y: rect.maxY)

        path.move(to: startPoint)
        path.addLine(to: bottomPoint)
        path.move(to: startCurvePoint)
        path.addQuadCurve(to: endCurvePoint, control: CGPoint(x: rect.midX, y: rect.midY))

        return path.strokedPath(style)
    }
}

private struct TriangleShape: Shape {
    let size: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: rect.maxX + 1, y: rect.midY)
        path.move(to: startPoint)

        path.addLine(to: CGPoint(x: startPoint.x - size, y: startPoint.y - size / 2))
        path.addLine(to: CGPoint(x: startPoint.x - size, y: startPoint.y + size / 2))
        path.closeSubpath()

        return path
    }
}

struct ArrowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ArrowView(position: .first, width: 50, height: 50)
            ArrowView(position: .middle, width: 50, height: 50)
            ArrowView(position: .last, width: 50, height: 50)
        }
    }
}
