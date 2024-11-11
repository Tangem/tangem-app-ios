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

            VStack(spacing: .zero) {
                Spacer()

                content

                Spacer()
            }
            .padding(.horizontal, 50)
        }
        .navigationTitle(Text(viewModel.title))
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

struct ProgressDots: View {
    let style: Style
    @State private var loading = false

    var body: some View {
        HStack(spacing: style.spacing) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(Colors.Icon.accent)
                    .frame(width: style.size, height: style.size)
                    .scaleEffect(loading ? 0.75 : 1)
                    .opacity(loading ? 0.25 : 1)
                    .animation(animation(index: index), value: loading)
            }
        }
        .onAppear {
            loading = true
        }
    }

    func animation(index: Int) -> Animation {
        .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
            // Start animation with delay depends of index
            // Index(0) -> delay(0)
            // Index(1) -> delay(0.3)
            // Index(2) -> delay(0.6)
            .delay(CGFloat(index) * 0.3)
    }
}

extension ProgressDots {
    enum Style: Hashable {
        case small
        case large

        var size: CGFloat {
            switch self {
            case .small: 3
            case .large: 8
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: 1
            case .large: 6
            }
        }
    }
}

#Preview {
    ProgressDots(style: .large)
}
