//
//  SendView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel
    @Namespace private var namespace

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let backgroundColor = Colors.Background.tertiary
    private let bottomGradientHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 14) {
            header

            ZStack(alignment: .bottom) {
                currentPage
                    .transition(pageContentTransition)

                bottomOverlay
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .animation(Constants.defaultAnimation, value: viewModel.step)
        .interactiveDismissDisabled(viewModel.shouldShowDismissAlert)
        .scrollDismissesKeyboardCompat(.immediately)
        .alert(item: $viewModel.alert) { $0.alert }
        .safeAreaInset(edge: .bottom) {
            bottomContainer
                .animation(Constants.defaultAnimation, value: viewModel.showTransactionButtons)
        }
    }

    private var pageContentTransition: AnyTransition {
        switch viewModel.stepAnimation {
        case .slideForward:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .slideBackward:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        case .moveAndFade:
            return .asymmetric(
                insertion: .offset(),
                removal: .opacity.animation(.spring(duration: SendView.Constants.animationDuration / 2))
            )
        }
    }

    @ViewBuilder
    private var header: some View {
        if let title = viewModel.title {
            HStack {
                closeButton

                // Making sure the header doesn't jump when changing the visibility of the fields
                ZStack {
                    headerText(title: title, subtitle: viewModel.subtitle, titleNamespaceId: SendViewNamespaceId.containerTitle.rawValue)

                    headerText(title: "Title", subtitle: "Subtitle", titleNamespaceId: nil)
                        .hidden()
                }
                .padding(.vertical, 0)
                .lineLimit(1)

                ZStack(alignment: .trailing) {
                    closeButton
                        .hidden()

                    if viewModel.showQRCodeButton {
                        Button(action: viewModel.scanQRCode) {
                            Assets.qrCode.image
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.primary1)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private var closeButton: some View {
        Button(Localization.commonClose, action: viewModel.dismiss)
            .foregroundColor(viewModel.closeButtonColor)
            .disabled(viewModel.closeButtonDisabled)
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func headerText(title: String, subtitle: String?, titleNamespaceId: String?) -> some View {
        VStack(spacing: 2) {
            // SwiftUI cannot animate the position and the contents of the same text view at the same time
            // Hence the duplicate title views
            if let subtitle = subtitle {
                headerTitleText(title: title, titleNamespaceId: titleNamespaceId)

                Text(subtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .transition(.opacity)
            } else {
                headerTitleText(title: title, titleNamespaceId: titleNamespaceId)
            }
        }
    }

    private func headerTitleText(title: String, titleNamespaceId: String?) -> some View {
        Text(title)
            .style(Fonts.Bold.body, color: Colors.Text.primary1)
            .frame(maxWidth: .infinity)
            .matchedGeometryEffectOptional(id: titleNamespaceId, in: titleNamespaceId != nil ? namespace : nil)
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step {
        case .amount:
            SendAmountView(
                viewModel: viewModel.sendAmountViewModel,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .amountMinTextScale(Constants.amountMinTextScale)
            .onAppear(perform: viewModel.onCurrentPageAppear)
            .onDisappear(perform: viewModel.onCurrentPageDisappear)
        case .destination:
            SendDestinationView(viewModel: viewModel.sendDestinationViewModel, namespace: namespace)
                .onAppear(perform: viewModel.onCurrentPageAppear)
                .onDisappear(perform: viewModel.onCurrentPageDisappear)
        case .fee:
            SendFeeView(viewModel: viewModel.sendFeeViewModel, namespace: namespace)
                .onAppear(perform: viewModel.onCurrentPageAppear)
                .onDisappear(perform: viewModel.onCurrentPageDisappear)
        case .summary:
            SendSummaryView(viewModel: viewModel.sendSummaryViewModel, namespace: namespace)
                .amountMinTextScale(Constants.amountMinTextScale)
                .onAppear(perform: viewModel.onCurrentPageAppear)
                .onDisappear(perform: viewModel.onCurrentPageDisappear)
        case .finish:
            SendFinishView(viewModel: viewModel.sendFinishViewModel, namespace: namespace)
                .onAppear(perform: viewModel.onCurrentPageAppear)
                .onDisappear(perform: viewModel.onCurrentPageDisappear)
        }
    }

    @ViewBuilder
    private var bottomContainer: some View {
        VStack(spacing: 10) {
            if viewModel.showTransactionButtons {
                HStack(spacing: 8) {
                    MainButton(
                        title: Localization.commonExplore,
                        icon: .leading(Assets.globe),
                        style: .secondary,
                        action: viewModel.explore
                    )
                    MainButton(
                        title: Localization.commonShare,
                        icon: .leading(Assets.share),
                        style: .secondary,
                        action: viewModel.share
                    )
                }
                .transition(.opacity)
            }

            HStack(spacing: 8) {
                if viewModel.showBackButton {
                    SendViewBackButton(
                        backgroundColor: backButtonStyle.background(isDisabled: false),
                        cornerRadius: backButtonStyle.cornerRadius(for: backButtonSize),
                        height: backButtonSize.height,
                        action: viewModel.back
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(SendView.Constants.backButtonAnimation, value: viewModel.showBackButton)
                }

                MainButton(
                    title: viewModel.mainButtonTitle,
                    icon: viewModel.mainButtonIcon,
                    style: .primary,
                    size: .default,
                    isLoading: viewModel.mainButtonLoading,
                    isDisabled: viewModel.mainButtonDisabled,
                    action: viewModel.next
                )
            }
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        LinearGradient(colors: [backgroundColor.opacity(0), backgroundColor], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .frame(maxHeight: bottomGradientHeight)
            .padding(.horizontal, 16)
            .allowsHitTesting(false)
    }
}

// MARK: - Back button

private struct SendViewBackButton: View {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            backgroundColor
                .cornerRadiusContinuous(cornerRadius)
                .overlay(
                    Assets.arrowLeftMini
                        .image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.primary1)
                )
                .frame(size: CGSize(bothDimensions: height))
        }
    }
}

extension SendView {
    enum Constants {
        static let amountMinTextScale = 0.5
        static let animationDuration: TimeInterval = 0.3
        static let defaultAnimation: Animation = .spring(duration: animationDuration)
        static let backButtonAnimation: Animation = .easeOut(duration: 0.1)
        static let sectionContentAnimation: Animation = .easeOut(duration: animationDuration)
        static let hintViewTransition: AnyTransition = .asymmetric(insertion: .offset(y: 20), removal: .identity).combined(with: .opacity)

        static func auxiliaryViewTransition(for step: SendStep) -> AnyTransition {
            let offset: CGFloat
            switch step {
            case .destination, .amount:
                offset = 100
            case .fee:
                offset = 250
            case .summary:
                offset = 100
            case .finish:
                assertionFailure("WHY")
                return .identity
            }

            return .offset(y: offset).combined(with: .opacity)
        }
    }
}

extension SendView {
    enum StepAnimation {
        case slideForward
        case slideBackward
        case moveAndFade
    }
}

// MARK: - Preview

/*
 struct SendView_Preview: PreviewProvider {
     static let card = FakeUserWalletModel.wallet3Cards

     static let viewModel = SendViewModel(
         walletName: card.userWalletName,
         walletModel: card.walletModelsManager.walletModels.first!,
         userWalletModel: card,
         transactionSigner: TransactionSignerMock(),
         sendType: .send,
         emailDataProvider: EmailDataProviderMock(),
         canUseFiatCalculation: true,
         coordinator: SendRoutableMock()
     )

     static var previews: some View {
         SendView(viewModel: viewModel)
             .previewDisplayName("Full screen")

         NavHolder()
             .sheet(isPresented: .constant(true)) {
                 SendView(viewModel: viewModel)
             }
             .previewDisplayName("Sheet")
     }
 }
 */
