//
//  MarketsTokenDetailsView+Skeletons.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension MarketsTokenDetailsView {
    struct DescriptionBlockSkeletons: View {
        var body: some View {
            VStack(spacing: .zero) {
                description
            }
        }

        private var description: some View {
            // We need to use here odd value otherwise transition between skeleton and text will be with offset.
            // We can't specify line height in text but we can adapt skeletons spacing
            VStack(alignment: .leading, spacing: 5) {
                ForEach(0 ... 1) { _ in
                    skeletonView(width: .infinity, height: 14)
                }

                skeletonView(width: .infinity, height: 14)
                    .padding(.trailing, 72)
            }
        }

        private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
            SkeletonView()
                .cornerRadiusContinuous(3)
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
        }
    }

    struct ContentBlockSkeletons: View {
        var body: some View {
            VStack(spacing: 14) {
                insights

                securityScore

                metrics

                pricePerformance

                listedOnExchanges

                links
            }
        }

        private var portfolio: some View {
            VStack(spacing: 10) {
                HStack {
                    Text(Localization.marketsCommonMyPortfolio)
                        .lineLimit(1)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    skeletonView(width: .infinity, height: 15)

                    skeletonView(width: 218, height: 15)
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var insights: some View {
            VStack(spacing: .zero) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

                ForEach(0 ... 1) { _ in
                    fillableBlocks
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var securityScore: some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    skeletonView(width: 106, height: 16)

                    skeletonView(width: 106, height: 16)
                }

                Spacer()

                skeletonView(width: 134, height: 20)
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var metrics: some View {
            VStack(spacing: .zero) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

                ForEach(0 ... 2) { _ in
                    fillableBlocks
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var pricePerformance: some View {
            VStack(spacing: 12) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

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

        private var listedOnExchanges: some View {
            HStack {
                VStack(spacing: 8) {
                    Text(Localization.marketsTokenDetailsListedOn)
                        .style(Fonts.Bold.footnote.weight(.semibold), color: Colors.Text.tertiary)

                    skeletonView(width: 82, height: 20)
                }

                Spacer()
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var links: some View {
            VStack(alignment: .leading, spacing: 12) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.horizontal, 14)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

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
                            Separator(height: .minimal, color: Colors.Stroke.primary)
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
            .padding(.top, 10)
        }

        private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
            SkeletonView()
                .cornerRadiusContinuous(3)
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
        }
    }
}

extension MarketsTokenDetailsView.ContentBlockSkeletons {
    enum Constants {
        static let bottomPaddingTitleConstant: CGFloat = 8
    }
}

#Preview {
    ScrollView {
        MarketsTokenDetailsView.ContentBlockSkeletons()
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
