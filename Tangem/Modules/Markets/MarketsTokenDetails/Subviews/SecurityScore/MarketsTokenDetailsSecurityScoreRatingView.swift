//
//  MarketsTokenDetailsSecurityScoreRatingView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsSecurityScoreRatingView: View {
    let ratingBullet: MarketsTokenDetailsSecurityScoreViewModel.RatingBullet
    let dimensions: CGSize

    var body: some View {
        ZStack {
            makeAsset(Assets.starThickFill)
                .mask(alignment: .leading) {
                    Rectangle()
                        .frame(width: dimensions.width * ratingBullet.value, height: dimensions.height)
                }

            makeAsset(Assets.starThick)
        }
    }

    @ViewBuilder
    private func makeAsset(_ imageType: ImageType) -> some View {
        imageType
            .image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.accent)
            .frame(size: dimensions)
    }
}

// MARK: - Previews

#Preview {
    MarketsTokenDetailsSecurityScoreRatingView(ratingBullet: .init(value: 1.0), dimensions: .init(bothDimensions: 24.0))

    MarketsTokenDetailsSecurityScoreRatingView(ratingBullet: .init(value: 0.4), dimensions: .init(bothDimensions: 24.0))

    MarketsTokenDetailsSecurityScoreRatingView(ratingBullet: .init(value: 0.1), dimensions: .init(bothDimensions: 24.0))
}
