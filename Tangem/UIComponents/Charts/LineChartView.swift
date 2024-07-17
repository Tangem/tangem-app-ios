//
//  ChartsView.swift
//  ContextMenu
//
//  Created by skibinalexander on 16.07.2024.
//

import SwiftUI
import Charts

struct LineChartView: View {
    let color: Color
    let data: [Double]

    private var linearGradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.25), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var chartItems: [Item] {
        data.indexed().map { index, element in
            Item(id: index, value: element)
        }
    }

    private var scaleY: (min: Double, max: Double) {
        let values = chartItems.map { $0.value }
        return (values.min() ?? .zero, values.max() ?? .zero)
    }

    // MARK: - UI

    var body: some View {
        GeometryReader { geometry in
            linePath(for: geometry.size)
                .stroke(color, lineWidth: 1)
                .background(
                    LinearGradient(
                        colors: [color.opacity(0.25), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(gradientPath(for: geometry.size))
                )
        }
    }

    // MARK: - Private Implementation

    private func linePath(for size: CGSize) -> Path {
        guard
            data.count >= 2,
            let minX = data.min(),
            let maxX = data.max()
        else {
            return Path()
        }

        let dx = size.width / Double(data.count - 1)
        let points = data.enumerated().map { index, x in
            CGPoint(
                x: dx * Double(index),
                y: (maxX - x) / (maxX - minX) * size.height
            )
        }

        return Path { path in
            if let first = points.first {
                path.move(to: first)
            }

            for point in points.dropFirst(1) {
                path.addLine(to: point)
            }
        }
    }

    private func gradientPath(for size: CGSize) -> Path {
        var path = linePath(for: size)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        return path
    }
}

extension LineChartView {
    struct Item: Identifiable, Equatable {
        let id: Int
        let value: Double
    }
}

#Preview {
    HStack(spacing: 30) {
        LineChartView(
            color: Color.red,
            data: [1, 7, 3, 5, 13].reversed()
        )
        .frame(width: 100, height: 50, alignment: .center)

        LineChartView(
            color: Color.blue,
            data: [2, 4, 3, 5, 6]
        )
        .frame(width: 120, height: 50, alignment: .center)
    }
}
