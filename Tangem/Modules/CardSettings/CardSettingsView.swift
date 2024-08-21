//
//  CardSettingsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardSettingsView: View {
    @ObservedObject var viewModel: CardSettingsViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView(spacing: 24) {
                GroupedSection(viewModel.cardInfoSection) {
                    DefaultRowView(viewModel: $0)
                }

                GroupedSection(viewModel.securityModeSection) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(viewModel.securityModeFooterMessage)
                }

                GroupedSection(viewModel.accessCodeRecoverySection) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(Localization.cardSettingsAccessCodeRecoveryFooter)
                }

                GroupedSection(viewModel.resetToFactoryViewModel) {
                    DefaultRowView(viewModel: $0)
                        .appearance(.destructiveButton)
                } footer: {
                    DefaultFooterView(viewModel.resetToFactoryFooterMessage)
                }
            }
            .interContentPadding(8)
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.cardSettingsTitle), displayMode: .inline)
    }
}
