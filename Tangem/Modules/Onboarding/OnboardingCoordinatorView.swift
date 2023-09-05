//
//  OnboardingCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct OnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: OnboardingCoordinator

    private let bottomSheetBackground = Colors.Background.primary

    var body: some View {
        ZStack {
            content
                .navigationBarHidden(true)
                .transition(.withoutOpacity)
                .navigationLinks(links)

            sheets
        }
    }

    @ViewBuilder
    private var content: some View {
        if let singleCardViewModel = coordinator.singleCardViewModel {
            SingleCardOnboardingView(viewModel: singleCardViewModel)
        } else if let twinsViewModel = coordinator.twinsViewModel {
            TwinsOnboardingView(viewModel: twinsViewModel)
        } else if let walletViewModel = coordinator.walletViewModel {
            WalletOnboardingView(viewModel: walletViewModel)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.legacyMainCoordinator) {
                LegacyMainCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.mainCoordinator) {
                MainCoordinatorView(coordinator: $0)
            }
            .emptyNavigationLink()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.buyCryptoModel) {
                WebViewContainer(viewModel: $0)
            }
            .sheet(item: $coordinator.accessCodeModel) {
                OnboardingAccessCodeView(viewModel: $0)
            }
            .sheet(item: $coordinator.supportChatViewModel) {
                SupportChatView(viewModel: $0)
                    .edgesIgnoringSafeArea(.vertical)
            }
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.addressQrBottomSheetContentViewModel, settings: .init(backgroundColor: bottomSheetBackground)) {
                AddressQrBottomSheetContent(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(item: $coordinator.warningBankCardViewModel, settings: .init(backgroundColor: bottomSheetBackground)) {
                WarningBankCardView(viewModel: $0)
            }
    }
}
