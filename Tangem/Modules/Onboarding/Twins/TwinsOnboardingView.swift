//
//  TwinsOnboardingView.swift
//  Tangem
//
//  Created by Andrew Son on 26.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TwinsOnboardingView: View {
    @ObservedObject var viewModel: TwinsOnboardingViewModel

    private let screenSize: CGSize = UIScreen.main.bounds.size

    var isNavbarVisible: Bool {
        viewModel.isNavBarVisible
    }

    var isProgressBarVisible: Bool {
        if case .intro = currentStep {
            return false
        }

        if !viewModel.isInitialAnimPlayed {
            return false
        }

        return true
    }

    var currentStep: TwinsOnboardingStep { viewModel.currentStep }

    @ViewBuilder
    var customContent: some View {
        switch viewModel.currentStep {
        case .saveUserWallet:
            UserWalletStorageAgreementView(
                viewModel: viewModel.userWalletStorageAgreementViewModel,
                topInset: -viewModel.progressBarPadding
            )
        case .pushNotifications:
            if let pushNotificationsViewModel = viewModel.pushNotificationsViewModel {
                PushNotificationsPermissionRequestView(
                    viewModel: pushNotificationsViewModel,
                    topInset: -viewModel.progressBarPadding,
                    buttonsAxis: .vertical
                )
            }
        default:
            EmptyView()
        }
    }

    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
                .frame(maxWidth: screenSize.width)
                .zIndex(110)

            VStack(spacing: 0) {
                GeometryReader { geom in
                    ZStack(alignment: .center) {
                        let size = geom.size

                        // Navbar is added to ZStack instead of VStack because of wrong animation when container changed
                        // and cards jumps instead of smooth transition
                        NavigationBar(
                            title: viewModel.navbarTitle,
                            settings: .init(
                                title: .init(font: .system(size: 17, weight: .semibold)),
                                backgroundColor: .clear
                            ),
                            leftItems: {
                                BackButton(
                                    height: viewModel.navbarSize.height,
                                    isVisible: viewModel.isBackButtonVisible,
                                    isEnabled: viewModel.isBackButtonEnabled
                                ) {
                                    viewModel.backButtonAction()
                                }
                            },
                            rightItems: {
                                SupportButton(
                                    height: viewModel.navbarSize.height,
                                    isVisible: viewModel.isSupportButtonVisible,
                                    isEnabled: true
                                ) {
                                    viewModel.openSupport()
                                }
                            }
                        )
                        .offset(x: 0, y: -geom.size.height / 2 + (isNavbarVisible ? viewModel.navbarSize.height / 2 : 0))
                        .opacity(isNavbarVisible ? 1.0 : 0.0)

                        ProgressBar(height: viewModel.progressBarHeight, currentProgress: viewModel.currentProgress)
                            .offset(x: 0, y: -size.height / 2 + viewModel.navbarSize.height + viewModel.progressBarPadding)
                            .opacity(isProgressBarVisible ? 1.0 : 0.0)
                            .padding(.horizontal, 16)

                        if !viewModel.isCustomContentVisible {
                            let backgroundFrame = currentStep.backgroundFrame(in: size)
                            let backgroundOffset = currentStep.backgroundOffset(in: size)
                            OnboardingTopupBalanceView(
                                backgroundFrameSize: backgroundFrame,
                                cornerSize: currentStep.backgroundCornerRadius(in: size),
                                backgroundOffset: backgroundOffset,
                                balance: viewModel.cardBalance,
                                balanceUpdaterFrame: backgroundFrame,
                                balanceUpdaterOffset: backgroundOffset,
                                refreshAction: {
                                    viewModel.updateCardBalance()
                                },
                                refreshButtonState: viewModel.refreshButtonState,
                                refreshButtonSize: .medium,
                                refreshButtonOpacity: currentStep.backgroundOpacity
                            )

                            OnboardingCircleButton(
                                refreshAction: {
                                    viewModel.updateCardBalance()
                                },
                                state: currentStep.successCircleState,
                                size: .huge
                            )
                            .offset(y: 8)
                            .opacity(currentStep.successCircleOpacity)

                            AnimatedView(settings: viewModel.$supplementCardSettings) {
                                OnboardingCardView(
                                    placeholderCardType: .light,
                                    cardImage: viewModel.secondTwinImage,
                                    cardScanned: viewModel.displayTwinImages
                                )
                            }
                            AnimatedView(settings: viewModel.$mainCardSettings) {
                                OnboardingCardView(
                                    placeholderCardType: .dark,
                                    cardImage: viewModel.firstTwinImage,
                                    cardScanned: viewModel.displayTwinImages
                                )
                            }
                        }
                    }
                    .frame(size: geom.size)
                }
                .readGeometry(\.size) { size in
                    if !viewModel.isCustomContentVisible {
                        viewModel.setupContainer(with: size)
                    }
                }
                .frame(minHeight: viewModel.navbarSize.height + 20)

                if viewModel.isCustomContentVisible {
                    customContent
                        .layoutPriority(1)
                        .readGeometry(\.size) { size in
                            viewModel.setupContainer(with: size)
                        }
                }

                if !viewModel.isCustomContentVisible {
                    OnboardingTextButtonView(
                        title: viewModel.title,
                        subtitle: viewModel.subtitle,
                        buttonsSettings: .init(
                            main: viewModel.mainButtonSettings,
                            supplement: viewModel.supplementButtonSettings
                        ),
                        infoText: viewModel.infoText,
                        titleAction: {},
                        checkmarkText: currentStep.checkmarkText,
                        isCheckmarkChecked: $viewModel.alertAccepted
                    )
                }
            }
        }
        .background(
            TwinIntroBackgroundView(size: CGSize(
                width: screenSize.height * 1.2 * 1.2,
                height: screenSize.height * 1.2
            ))
            .offset(x: -screenSize.width / 2, y: -screenSize.height / 2)
            .opacity(currentStep.isBackgroundVisible ? 1 : 0)
        )
        .alert(item: $viewModel.alert, content: { binder in
            binder.alert
        })
        .preference(key: ModalSheetPreferenceKey.self, value: currentStep.isModal)
        .onAppear(perform: viewModel.onAppear)
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }
}

struct TwinsOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        TwinsOnboardingView(viewModel: TwinsOnboardingViewModel(
            input: PreviewData.previewTwinOnboardingInput,
            coordinator: OnboardingCoordinator()
        ))
    }
}
