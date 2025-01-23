//
//  SingleCardOnboardingView.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct SingleCardOnboardingView: View {
    @ObservedObject var viewModel: SingleCardOnboardingViewModel

    private let horizontalPadding: CGFloat = 16
    private let screenSize: CGSize = UIScreen.main.bounds.size

    var currentStep: SingleCardOnboardingStep { viewModel.currentStep }

    var isProgressBarVisible: Bool {
        return true
    }

    private var isTopItemsVisible: Bool {
        viewModel.isNavBarVisible
    }

    @ViewBuilder
    var customContent: some View {
        switch viewModel.currentStep {
        case .saveUserWallet:
            UserWalletStorageAgreementView(
                viewModel: viewModel.userWalletStorageAgreementViewModel,
                topInset: -viewModel.progressBarPadding
            )
        case .addTokens:
            if let addTokensViewModel = viewModel.addTokensViewModel {
                OnboardingAddTokensView(viewModel: addTokensViewModel)
            }
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
                .zIndex(100)

            VStack(spacing: 0) {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack(alignment: .center) {
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
                                    isEnabled: viewModel.isBackButtonEnabled,
                                    hPadding: horizontalPadding
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
                        .frame(size: viewModel.navbarSize)
                        .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height / 2 : 0))
                        .opacity(isTopItemsVisible ? 1.0 : 0.0)

                        ProgressBar(height: viewModel.progressBarHeight, currentProgress: viewModel.currentProgress)
                            .offset(x: 0, y: -size.height / 2 + (isTopItemsVisible ? viewModel.navbarSize.height + viewModel.progressBarPadding : 0))
                            .opacity(isTopItemsVisible && isProgressBarVisible ? 1.0 : 0.0)
                            .padding(.horizontal, horizontalPadding)

                        let backgroundFrame = viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundFrame(containerSize: size) : .zero
                        let backgroundOffset = viewModel.isInitialAnimPlayed ? currentStep.cardBackgroundOffset(containerSize: size) : .zero

                        if !viewModel.isCustomContentVisible {
                            AnimatedView(settings: viewModel.$supplementCardSettings) {
                                OnboardingCardView(
                                    placeholderCardType: .light,
                                    cardImage: nil,
                                    cardScanned: false
                                )
                            }
                            AnimatedView(settings: viewModel.$mainCardSettings) {
                                OnboardingCardView(
                                    placeholderCardType: .dark,
                                    cardImage: viewModel.mainImage,
                                    cardScanned: viewModel.isInitialAnimPlayed && viewModel.isCardScanned
                                )
                            }

                            OnboardingTopupBalanceView(
                                backgroundFrameSize: backgroundFrame,
                                cornerSize: currentStep.cardBackgroundCornerRadius(containerSize: size),
                                backgroundOffset: backgroundOffset,
                                balance: viewModel.cardBalance,
                                balanceUpdaterFrame: backgroundFrame,
                                balanceUpdaterOffset: backgroundOffset,
                                refreshAction: {
                                    viewModel.updateCardBalance()
                                },
                                refreshButtonState: viewModel.refreshButtonState,
                                refreshButtonSize: .medium,
                                refreshButtonOpacity: currentStep.balanceStackOpacity
                            )

                            OnboardingCircleButton(
                                refreshAction: {},
                                state: currentStep.successCircleState,
                                size: .huge
                            )
                            .offset(y: 8)
                            .opacity(currentStep.successCircleOpacity)
                        }
                    }
                    .position(x: size.width / 2, y: size.height / 2)
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
                        textOffset: currentStep.messagesOffset,
                        buttonsSettings: .init(
                            main: viewModel.mainButtonSettings,
                            supplement: viewModel.supplementButtonSettings
                        ),
                        infoText: viewModel.infoText
                    ) {
                        viewModel.closeOnboarding()
                    }
                }
            }
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .onAppear(perform: viewModel.onAppear)
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        SingleCardOnboardingView(viewModel: .init(
            input: PreviewData.previewNoteCardOnboardingInput,
            coordinator: OnboardingCoordinator()
        ))
    }
}

struct CardOnboardingBackgroundCircle: View {
    let scale: CGFloat

    var body: some View {
        Circle()
            .foregroundColor(.white)
            .frame(size: .init(width: 664, height: 664))
            .padding(10)
            .overlay(
                Circle()
                    .foregroundColor(Colors.Old.tangemBgGray)
                    .padding(38)
            )
            .background(
                Circle()
                    .foregroundColor(Colors.Old.tangemBgGray)
            )
            .edgesIgnoringSafeArea(.all)
            .scaleEffect(scale)
            .offset(x: 299, y: -228)
    }
}
