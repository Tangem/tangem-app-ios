//
//  AppSettingsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AppSettingsView: View {
    @ObservedObject private var viewModel: AppSettingsViewModel

    init(viewModel: AppSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                appCurrencySection

                warningSection

                savingWalletSection

                savingAccessCodesSection

                sensitiveTextAvailabilitySection

                themeSettingsSection
            }
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.appSettingsTitle), displayMode: .inline)
    }

    @ViewBuilder
    private var appCurrencySection: some View {
        GroupedSection(viewModel.currencySelectionViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    @ViewBuilder
    private var warningSection: some View {
        GroupedSection(viewModel.warningViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
    }

    private var savingWalletSection: some View {
        GroupedSection(viewModel.savingWalletViewModel) {
            DefaultToggleRowView(viewModel: $0)
                // Workaround for force rendering the view
                // Will be update in https://tangem.atlassian.net/browse/IOS-2524
                // Use @Published from directly from the ViewModel
                .id(viewModel.isSavingWallet)
        } footer: {
            DefaultFooterView(Localization.appSettingsSavedWalletFooter)
        }
    }

    private var savingAccessCodesSection: some View {
        GroupedSection(viewModel.savingAccessCodesViewModel) {
            DefaultToggleRowView(viewModel: $0)
                // Workaround for force rendering the view
                // Will be update in https://tangem.atlassian.net/browse/IOS-2524
                // Use @Published from directly from the ViewModel
                .id(viewModel.isSavingAccessCodes)
        } footer: {
            DefaultFooterView(Localization.appSettingsSavedAccessCodesFooter)
        }
    }

    private var sensitiveTextAvailabilitySection: some View {
        GroupedSection(viewModel.sensitiveTextAvailabilityViewModel) {
            DefaultToggleRowView(viewModel: $0)
        } footer: {
            DefaultFooterView(Localization.detailsRowDescriptionFlipToHide)
        }
    }

    private var themeSettingsSection: some View {
        GroupedSection(viewModel.themeSettingsViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }
}
