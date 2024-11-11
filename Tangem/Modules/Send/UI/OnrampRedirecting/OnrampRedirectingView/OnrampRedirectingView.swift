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

    var body: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea()

            content
        }
        .navigationTitle(Text(viewModel.title))
        .alert(item: $viewModel.alert) { $0.alert }
        .task {
            await viewModel.loadRedirectData()
        }
    }

    private var content: some View {
        VStack(alignment: .center, spacing: 24) {
            HStack(spacing: 12) {
                tangemIcon

                ProgressDots(style: .large)

                IconView(url: viewModel.providerImageURL, size: CGSize(width: 64, height: 64), cornerRadius: 8)
            }

            VStack(alignment: .center, spacing: 12) {
                Text("Redirecting to \(viewModel.providerName)...")
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text("You will be able to complete your transaction on the third-party provider, \(viewModel.providerName)")
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
