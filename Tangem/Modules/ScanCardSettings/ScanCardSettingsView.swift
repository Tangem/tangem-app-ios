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
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    Assets.cards.image
                        .padding(.vertical, 32)

                    VStack(alignment: .center, spacing: 16) {
                        Text(Localization.scanCardSettingsTitle)
                            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                            .multilineTextAlignment(.center)

                        Text(Localization.scanCardSettingsMessage)
                            .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

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
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text(Localization.cardSettingsTitle), displayMode: .inline)
    }
}

struct ScanCardSettingsView_Preview: PreviewProvider {
    static let viewModel = ScanCardSettingsViewModel(expectedUserWalletId: Data(), sdk: .init(), coordinator: DetailsCoordinator())

    static var previews: some View {
        ScanCardSettingsView(viewModel: viewModel)
            .deviceForPreview(.iPhone7)
    }
}
