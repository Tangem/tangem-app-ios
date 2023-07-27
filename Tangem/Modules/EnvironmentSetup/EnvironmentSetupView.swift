//
//  EnvironmentSetupView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct EnvironmentSetupView: View {
    @ObservedObject private var viewModel: EnvironmentSetupViewModel

    init(viewModel: EnvironmentSetupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                GroupedSection(viewModel.appSettingsTogglesViewModels) {
                    DefaultToggleRowView(viewModel: $0)
                } header: {
                    DefaultHeaderView("App settings")
                }

                GroupedSection(viewModel.additionalSettingsViewModels) { viewModel in
                    DefaultRowView(viewModel: viewModel)
                } header: {
                    DefaultHeaderView("Additional settings")
                }

                GroupedSection(viewModel.featureStateViewModels) { viewModel in
                    FeatureStateRowView(viewModel: viewModel)
                } header: {
                    DefaultHeaderView("Feature toggles")
                }

                promotionProgramControls
            }
        }
        .navigationBarTitle(Text("Environment setup"))
        .navigationBarItems(trailing: exitButton)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var promotionProgramControls: some View {
        VStack(spacing: 30) {
            Text("PROMOTION PROGRAM")
                .font(.headline)

            VStack(spacing: 15) {
                HStack {
                    Text("Current promo code: \(viewModel.currentPromoCode)")

                    Button {
                        viewModel.copyCurrentPromoCode()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Color.blue)
                    }
                }

                Button("Reset promo codes", action: viewModel.resetCurrentPromoCode)
                    .foregroundColor(Color.red)
            }

            VStack(spacing: 15) {
                Text("Finished program names: \(viewModel.finishedPromotionNames)")

                Button("Reset finished programs", action: viewModel.resetFinishedPromotionNames)
                    .foregroundColor(Color.red)
            }

            VStack(spacing: 15) {
                Text("Awarded program names: \(viewModel.awardedPromotionNames)")

                Text("Reset award for this card on the backend (tangem-dev only)")
                    .multilineTextAlignment(.center)

                Button("Reset award", action: viewModel.resetAward)
                    .foregroundColor(Color.red)
            }
        }
    }

    private var exitButton: some View {
        Button("Exit", action: viewModel.showExitAlert)
            .animation(nil)
    }
}

struct EnvironmentSetupView_Preview: PreviewProvider {
    static let viewModel = EnvironmentSetupViewModel(coordinator: EnvironmentSetupRoutableMock(), cardId: "AC01")

    static var previews: some View {
        NavigationView {
            EnvironmentSetupView(viewModel: viewModel)
        }
    }
}
