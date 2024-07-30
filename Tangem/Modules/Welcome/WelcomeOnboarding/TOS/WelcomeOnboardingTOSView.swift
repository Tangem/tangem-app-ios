//
//  WelcomeOnboardingTOSView.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingTOSView: View {
    @ObservedObject var viewModel: WelcomeOnboardingTOSViewModel

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                TOSView(viewModel: .init())

                MainButton(
                    title: Localization.commonAccept,
                    action: viewModel.didTapAccept
                )
                .padding(.top, 14)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }
}

#Preview {
    WelcomeOnboardingTOSView(viewModel: .init(delegate: WelcomeOnboardingTOSDelegateStub()))
}
