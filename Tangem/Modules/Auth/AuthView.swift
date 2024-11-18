//
//  AuthView.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel
    private var namespace: Namespace.ID?

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        unlockView
            .alert(item: $viewModel.error, content: { $0.alert })
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
            .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }

    private var unlockView: some View {
        VStack(spacing: 0) {
            Spacer()

            TangemIconView()
                .matchedGeometryEffectOptional(id: TangemIconView.namespaceId, in: namespace)

            Text(Localization.welcomeUnlockTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .padding(.bottom, 14)

            Text(Localization.welcomeUnlockDescription(BiometricAuthorizationUtils.biometryType.name))
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            MainButton(
                title: viewModel.unlockWithBiometryButtonTitle,
                style: .secondary,
                isDisabled: viewModel.isScanningCard,
                action: viewModel.unlockWithBiometryButtonTapped
            )
            .padding(.bottom, 11)

            MainButton(
                title: Localization.welcomeUnlockCard,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                isLoading: viewModel.isScanningCard,
                action: viewModel.unlockWithCard
            )
        }
        .padding([.top, .horizontal])
        .padding(.bottom, 6)
    }
}

extension AuthView: Setupable {
    func setNamespace(_ namespace: Namespace.ID?) -> Self {
        map { $0.namespace = namespace }
    }
}

struct AuthView_Preview: PreviewProvider {
    static let viewModel = AuthViewModel(coordinator: AuthCoordinator())

    static var previews: some View {
        AuthView(viewModel: viewModel)
    }
}
