//
//  ScanCardSettingsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScanCardSettingsView: View {
    @ObservedObject private var viewModel: ScanCardSettingsViewModel

    init(viewModel: ScanCardSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .center, spacing: 40) {
                        topView
                            .frame(height: proxy.size.height / 2, alignment: .bottom)

                        bottomView
                    }
                }
            }

            MainButton(
                title: Localization.scanCardSettingsButton,
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isLoading,
                action: viewModel.scanCard
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Colors.Background.tertiary.ignoresSafeArea())
    }

    @ViewBuilder
    private var topView: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Colors.Button.secondary)
                .padding(.horizontal, 30)

            image
        }
        .padding(.horizontal, 30)
    }

    @ViewBuilder
    private var bottomView: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(Localization.scanCardSettingsTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(Localization.scanCardSettingsMessage)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.icon {
        case .loading:
            Color.clear
        case .loaded(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .failedToLoad:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct ScanCardSettingsView_Preview: PreviewProvider {
    static let viewModel = ScanCardSettingsViewModel(
        input: .init(
            cardImagePublisher: .just(output: .embedded(Assets.Onboarding.walletCard.uiImage)),
            cardScanner: CommonCardScanner()
        ),
        coordinator: ScanCardSettingsCoordinator()
    )

    static var previews: some View {
        NavHolder()
            .sheet(item: .constant(viewModel)) {
                ScanCardSettingsView(viewModel: $0)
            }
    }
}
