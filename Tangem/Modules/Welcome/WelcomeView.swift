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
        StoriesView(viewModel: viewModel.storiesModel)
            .alert(item: $viewModel.error, content: { $0.alert })
            .environment(\.colorScheme, .dark)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .background(
                ScanTroubleshootingView(
                    isPresented: $viewModel.showTroubleshootingView,
                    tryAgainAction: viewModel.tryAgain,
                    requestSupportAction: viewModel.requestSupport,
                    openScanCardManualAction: viewModel.openScanCardManual
                )
            )
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: WelcomeViewModel(coordinator: WelcomeCoordinator(), storiesModel: .init()))
    }
}
