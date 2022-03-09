//
//  WelcomeOnboardingView.swift
//  Tangem
//
//  Created by Andrew Son on 30.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    
    @ObservedObject var viewModel: WelcomeOnboardingViewModel
    @ObservedObject var storiesModel: StoriesViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var currentStep: WelcomeStep { .welcome }
    
    var body: some View {
        ZStack {
            StoriesView(viewModel: storiesModel) {
                storiesModel.currentStoryPage(
                    scanCard: viewModel.scanCard,
                    orderCard: viewModel.orderCard,
                    searchTokens: viewModel.searchTokens
                )
            }
            .statusBar(hidden: true)
            .environment(\.colorScheme, storiesModel.currentPage.colorScheme)
            .actionSheet(item: $viewModel.discardAlert, content: { $0.sheet })
            
            ScanTroubleshootingView(isPresented: $navigation.readToTroubleshootingScan) {
                self.viewModel.scanCard()
            } requestSupportAction: {
                self.viewModel.failedCardScanTracker.resetCounter()
                self.navigation.readToSendEmail = true
            }
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.welcomeToBackup, content: {
                    OnboardingBaseView(viewModel: viewModel.assembly.getCardOnboardingViewModel())
                        .presentation(modal: viewModel.isBackupModal, onDismissalAttempt: {
                            viewModel.assembly.getWalletOnboardingViewModel()?.backButtonAction()
                        }, onDismissed: nil)
                        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                            viewModel.isBackupModal = value
                        })
                        .environmentObject(navigation)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToSendEmail, content: {
                    MailView(dataCollector: viewModel.failedCardScanTracker, support: .tangem, emailType: .failedToScanCard)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.onboardingToDisclaimer, content: {
                    DisclaimerView(style: .sheet(acceptCallback: viewModel.acceptDisclaimer), showAccept: true)
                        .presentation(modal: true, onDismissalAttempt: nil, onDismissed: viewModel.disclaimerDismissed)
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToShop, content: {
                    NavigationView {
                        ShopContainerView(viewModel: viewModel.assembly.makeShopViewModel())
                            .environmentObject(navigation)
                    }
                })
            
            Color.clear.frame(width: 1, height: 1)
                .sheet(isPresented: $navigation.readToTokenList) {
                    TokenListView(viewModel: viewModel.assembly.makeTokenListViewModel(mode: .show))
                        .environmentObject(navigation)
                }
        }
        .alert(item: $viewModel.error, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        WelcomeOnboardingView(viewModel: assembly.getLetsStartOnboardingViewModel(with: { _ in }), storiesModel: assembly.makeWelcomeStoriesModel())
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
