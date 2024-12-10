//
//  OnrampRedirectingView.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampRedirectingView: View {
    @ObservedObject var viewModel: OnrampRedirectingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea()

            content
        }
        .navigationTitle(Text(viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear {
            viewModel.onAppear()
            viewModel.update(colorScheme: colorScheme)
        }
        .onChange(of: colorScheme) { viewModel.update(colorScheme: $0) }
        .task { await viewModel.loadRedirectData() }
    }

    private var content: some View {
        VStack(alignment: .center, spacing: 24) {
            HStack(spacing: 12) {
                tangemIcon

                ProgressDots(style: .large)

                IconView(url: viewModel.providerImageURL, size: CGSize(width: 64, height: 64), cornerRadius: 8)
            }

            VStack(alignment: .center, spacing: 12) {
                Text(Localization.onrampRedirectingToProviderTitle(viewModel.providerName))
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(Localization.onrampRedirectingToProviderSubtitle(viewModel.providerName))
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 50)
    }

    var tangemIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Colors.Background.action)
                .frame(width: 64, height: 64)

            Assets.tangemIconMedium.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.primary1)
        }
    }
}
