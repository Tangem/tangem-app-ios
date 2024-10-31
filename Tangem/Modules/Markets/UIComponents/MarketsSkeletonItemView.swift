//
//  MarketsSkeletonItemView.swift
//  Tangem
//
//  Created by skibinalexander on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsSkeletonItemView: View {
    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        HStack(spacing: 12) {
            IconView(url: nil, size: iconSize, forceKingfisher: true)

            VStack {
                tokenInfoView
            }

            Spacer()

            VStack(alignment: .trailing) {
                HStack(alignment: .center, spacing: .zero) {
                    priceHistoryView
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .animation(nil) // Disable animations on scroll reuse
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstBaselineCustom, spacing: 4) {
                makeSkeletonView(by: Constants.skeletonMediumWidthValue)
            }

            HStack(spacing: 6) {
                makeSkeletonView(by: Constants.skeletonSmallWidthValue)
            }
        }
    }

    private var priceHistoryView: some View {
        VStack {
            makeSkeletonView(by: Constants.skeletonMediumWidthValue)
        }
        .frame(width: 56, height: 32, alignment: .center)
    }

    private func makeSkeletonView(by value: String) -> some View {
        Text(value)
            .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            .skeletonable(isShown: true)
    }
}

extension MarketsSkeletonItemView {
    enum Constants {
        static let skeletonMediumWidthValue: String = "---------"
        static let skeletonSmallWidthValue: String = "------"
    }
}

#Preview {
    return ScrollView(.vertical) {
        ForEach(0 ..< 10) { _ in
            MarketsSkeletonItemView()
        }
    }
}
