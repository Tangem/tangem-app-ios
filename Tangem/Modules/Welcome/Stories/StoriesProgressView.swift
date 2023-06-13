//
//  StoriesProgressView.swift
//  StoriesDemo
//
//  Created by Andrey Chukavin on 26.01.2022.
//

import SwiftUI

struct StoriesProgressView: View {
    let pages: [WelcomeStoryPage]
    let currentPageIndex: Int
    @Binding var progress: Double

    private let barHeight: Double = 2
    private let barSpacing: Double = 5
    private let barBackgroundOpacity: Double = 0.2

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0 ..< pages.count, id: \.self) { index in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.primary.opacity(barBackgroundOpacity))
                        .overlay(overlay(index, width: geo.size.width), alignment: .leading)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxHeight: barHeight)
    }

    @ViewBuilder
    func overlay(_ index: Int, width: CGFloat) -> some View {
        if index < currentPageIndex {
            Color.primary
        } else if index > currentPageIndex {
            EmptyView()
        } else {
            Color.primary.frame(width: progress * width)
        }
    }
}

struct StoriesProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .center) {
            Color.purple
            StoriesProgressView(pages: WelcomeStoryPage.allCases, currentPageIndex: 0, progress: .constant(0.3))
                .padding()
                .preferredColorScheme(.dark)
        }
        .previewLayout(.fixed(width: 400, height: 100))
    }
}
