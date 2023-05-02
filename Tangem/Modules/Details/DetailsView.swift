//
//  DetailsView.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct DetailsView: View {
    @ObservedObject private var viewModel: DetailsViewModel
    @State private var socialNetworksViewSize: CGSize = .zero

    init(viewModel: DetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GroupedScrollView {
                walletConnectSection

                GroupedSection(viewModel.supportSectionModels) {
                    DefaultRowView(viewModel: $0)
                }

                settingsSection

                legalSection

                environmentSetupSection

                Color.clear.frame(height: socialNetworksViewSize.height)
            }

            socialNetworks
                .readSize { socialNetworksViewSize = $0 }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.detailsTitle), displayMode: .inline)
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Wallet Connect Section

    @ViewBuilder
    private var walletConnectSection: some View {
        GroupedSection(viewModel.walletConnectRowViewModel) {
            WalletConnectRowView(viewModel: $0)
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        GroupedSection(viewModel.settingsSectionViewModels) {
            DefaultRowView(viewModel: $0)
        } footer: {
            if viewModel.canCreateBackup {
                DefaultFooterView(Localization.detailsRowTitleCreateBackupFooter)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        GroupedSection(viewModel.legalSectionViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var socialNetworks: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack(spacing: 16) {
                ForEach(SocialNetwork.allCases) { network in
                    socialNetworkView(network: network)
                }
            }

            if let applicationInfoFooter = viewModel.applicationInfoFooter {
                Text(applicationInfoFooter)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, max(16, UIApplication.safeAreaInsets.bottom))
        .background(Colors.Background.secondary)
    }

    @ViewBuilder
    private var environmentSetupSection: some View {
        GroupedSection(viewModel.environmentSetupViewModel) {
            DefaultRowView(viewModel: $0)
        } header: {
            DefaultHeaderView("Setup environment in app")
        }
    }

    private func socialNetworkView(network: SocialNetwork) -> some View {
        Button(action: {
            viewModel.openSocialNetwork(network: network)
        }) {
            network.icon.image
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailsView(
                viewModel: DetailsViewModel(
                    cardModel: PreviewCard.tangemWalletEmpty.cardModel,
                    coordinator: DetailsCoordinator()
                )
            )
        }
        .navigationViewStyle(.stack)
    }
}
