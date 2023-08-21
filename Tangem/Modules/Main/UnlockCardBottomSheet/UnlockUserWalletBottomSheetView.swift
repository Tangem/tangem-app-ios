//
//  UnlockUserWalletBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 15/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct UnlockUserWalletBottomSheetView: View {
    @ObservedObject var viewModel: UnlockUserWalletBottomSheetViewModel

    var body: some View {
        VStack(spacing: 0) {
            Assets.lockBig.image
                .foregroundColor(Colors.Icon.primary1)
                .padding(.top, 46)
                .padding(.bottom, 30)

            Text(Localization.commonUnlockNeeded)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .padding(.bottom, 14)

            Text(Localization.unlockWalletDescriptionFull(BiometricAuthorizationUtils.biometryType.name))
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.bottom, 56)
                .padding(.horizontal, 34)

            MainButton(
                title: Localization.userWalletListUnlockAll(BiometricAuthorizationUtils.biometryType.name),
                action: viewModel.unlockWithBiometry
            )
            .padding(.bottom, 10)

            MainButton(
                title: Localization.scanCardSettingsButton,
                icon: .trailing(Assets.tangemIcon),
                style: .secondary,
                isLoading: viewModel.isScannerBusy,
                action: viewModel.unlockWithCard
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .alert(item: $viewModel.error) { $0.alert }
    }
}

struct UnlockUserWalletBottomSheetView_Previews: PreviewProvider {
    class FakeUnlockUserWalletDelegate: UnlockUserWalletBottomSheetDelegate {
        func unlockedWithBiometry() {
            print("Unlocked with biometry")
        }

        func userWalletUnlocked(_ userWalletModel: UserWalletModel) {
            print("Unlocked with card: \(userWalletModel.userWalletId.stringValue)")
        }

        func showTroubleshooting() {
            print("Request troubleshooting")
        }
    }

    static let delegate = FakeUnlockUserWalletDelegate()
    static var bottomSheetModel: UnlockUserWalletBottomSheetViewModel = {
        let lockedUserWalletModel = FakeUserWalletModel.twins
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [lockedUserWalletModel])

        return UnlockUserWalletBottomSheetViewModel(
            userWalletModel: lockedUserWalletModel,
            delegate: delegate
        )
    }()

    static var previews: some View {
        StatefulPreviewWrapper(UnlockUserWalletBottomSheetViewModel?.none, content: { state in
            VStack {
                Button("Open bottom sheet") {
                    state.wrappedValue = bottomSheetModel
                }

                NavHolder()
                    .bottomSheet(item: state, settings: .init(backgroundColor: Colors.Background.primary)) { model in
                        UnlockUserWalletBottomSheetView(viewModel: model)
                    }
            }
        })
    }
}
