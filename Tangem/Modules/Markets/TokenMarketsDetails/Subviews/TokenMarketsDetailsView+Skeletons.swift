//
//  TokenMarketsDetailsView+Skeletons.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension TokenMarketsDetailsView {
    struct ContentBlockSkeletons: View {
        var body: some View {
            VStack(spacing: 14) {
                insights

                securityScore

                metrics

                pricePerformance

                links
            }
            .padding(.horizontal, 16)
        }

        private var insights: some View {
            VStack(spacing: 0) {
                HStack {
                    Text(Localization.marketsTokenDetailsInsights)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    MarketsPickerView(
                        marketPriceIntervalType: .constant(.day),
                        options: [.day, .month, .year],
                        shouldStretchToFill: false,
                        titleFactory: { $0.rawValue }
                    )
                }

                ForEach(0 ... 1) { _ in
                    fillableBlocks
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var securityScore: some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .center, spacing: 4) {
                        Text(Localization.marketsTokenDetailsSecurityScore)
                            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                        Assets.infoCircle16.image
                            .foregroundStyle(Colors.Icon.informative)
                    }

                    skeletonView(width: 106, height: 16)
                }

                Spacer()

                skeletonView(width: 134, height: 20)
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var metrics: some View {
            VStack(spacing: 0) {
                HStack {
                    Text(Localization.marketsTokenDetailsMetrics)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer(minLength: 10)

                    skeletonView(width: 70, height: 18)
                }

                ForEach(0 ... 2) { _ in
                    fillableBlocks
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var pricePerformance: some View {
            VStack(spacing: 12) {
                HStack {
                    Text(Localization.marketsTokenDetailsPricePerformance)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    MarketsPickerView(
                        marketPriceIntervalType: .constant(.day),
                        options: [.day, .month, .year],
                        shouldStretchToFill: false,
                        titleFactory: { $0.rawValue }
                    )
                }

                HStack {
                    skeletonView(width: 28, height: 18)

                    Spacer()

                    skeletonView(width: 38, height: 18)
                }

                skeletonView(width: .infinity, height: 6)

                HStack {
                    skeletonView(width: 60, height: 21)

                    Spacer()

                    skeletonView(width: 60, height: 21)
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var links: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localization.marketsTokenDetailsLinks)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 16)

                ForEach(0 ... 2) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        skeletonView(width: 74, height: 18)
                            .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            ForEach(0 ... 2) { _ in
                                SkeletonView()
                                    .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                                    .cornerRadiusContinuous(14)
                            }
                        }
                        .padding(.horizontal, 16)

                        if index != 2 {
                            Separator(height: .exact(0.5), color: Colors.Stroke.primary, axis: .horizontal)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action, horizontalPadding: 0)
        }

        private var fillableBlocks: some View {
            HStack(spacing: 12) {
                ForEach(0 ... 1) { _ in
                    VStack(alignment: .leading, spacing: 4) {
                        skeletonView(width: .infinity, height: 18)

                        skeletonView(width: 70, height: 21)
                    }
                }
            }
            .padding(.vertical, 10)
        }

        private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
            SkeletonView()
                .cornerRadiusContinuous(3)
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
        }
    }
}

#Preview {
    ScrollView {
        TokenMarketsDetailsView.ContentBlockSkeletons()
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
