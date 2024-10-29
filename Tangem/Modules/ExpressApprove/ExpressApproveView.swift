//
//  ExpressApproveView.swift
//  Tangem
//
//  Created by Sergey Balashov on 21.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressApproveView: View {
    @ObservedObject private var viewModel: ExpressApproveViewModel

    init(viewModel: ExpressApproveViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            headerView

            VStack(spacing: 22) {
                GroupedSection(viewModel.menuRowViewModel) {
                    DefaultMenuRowView(viewModel: $0, selection: $viewModel.selectedAction)
                } footer: {
                    DefaultFooterView(Localization.givePermissionPolicyTypeFooter)
                }
                .backgroundColor(Colors.Background.action)

                GroupedSection(viewModel.feeRowViewModel) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(viewModel.feeFooterText)
                }
                .backgroundColor(Colors.Background.action)

                buttons
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
        .alert(item: $viewModel.errorAlert) { $0.alert }
    }

    private var headerView: some View {
        ZStack(alignment: .topTrailing) {
            BottomSheetHeaderView(title: Localization.swappingPermissionHeader, subtitle: viewModel.subtitle)
                .padding(.horizontal, 16)

            Button(action: viewModel.didTapInfoButton) {
                Assets.infoIconMini.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .padding(.top, 4)
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.commonApprove,
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.mainButtonIsDisabled,
                action: viewModel.didTapApprove
            )

            MainButton(
                title: Localization.commonCancel,
                style: .secondary,
                action: viewModel.didTapCancel
            )
        }
        // This fix for text's font in the cancel button, it shrink with no reason
        .minimumScaleFactor(1)
    }
}

struct ExpressApproveView_Preview: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = BottomSheetCoordinator()

        var body: some View {
            ZStack {
                Colors.Background.primary
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $coordinator.item, backgroundColor: Colors.Background.tertiary) {
                        ExpressApproveView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressApproveRoutable {
        @Published var item: ExpressApproveViewModel?

        func toggleItem() {
            if item == nil {
                item = ExpressModulesFactoryMock().makeExpressApproveViewModel(providerName: "1inch", selectedPolicy: .unlimited, coordinator: self)
            } else {
                item = nil
            }
        }

        func didSendApproveTransaction() {
            item = nil
        }

        func userDidCancel() {
            item = nil
        }
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.light)

        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
