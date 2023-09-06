//
//  WelcomeView.swift
//  Tangem
//
//  Created by Andrew Son on 30.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        storiesView
            .alert(item: $viewModel.error, content: { $0.alert })
            .onAppear(perform: viewModel.onAppear)
            .onDidAppear(viewModel.onDidAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .background(
                ScanTroubleshootingView(
                    isPresented: $viewModel.showTroubleshootingView,
                    tryAgainAction: viewModel.tryAgain,
                    requestSupportAction: viewModel.requestSupport
                )
            )
    }

    var storiesView: some View {
        StoriesView(viewModel: viewModel.storiesModel) { [weak viewModel] in
            if let viewModel = viewModel {
                viewModel.storiesModel.currentStoryPage(
                    isScanning: $viewModel.isScanningCard,
                    scanCard: viewModel.scanCardTapped,
                    orderCard: viewModel.orderCard,
                    openPromotion: viewModel.openPromotion,
                    searchTokens: viewModel.openTokensList
                )
            }
        }
        .statusBar(hidden: true)
        .environment(\.colorScheme, viewModel.storiesModel.currentPage.colorScheme)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: WelcomeViewModel(shouldScanOnAppear: false, coordinator: WelcomeCoordinator()))
    }
}
