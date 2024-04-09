//
//  SendView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @Namespace var namespace

    @ObservedObject var viewModel: SendViewModel

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let backgroundColor = Colors.Background.tertiary
    private let bottomGradientHeight: CGFloat = 150

    @State private var navigationButtonsHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 14) {
            header

            ZStack(alignment: .bottom) {
                currentPage
                    .overlay(bottomOverlay, alignment: .bottom)
                    .transition(pageContentTransition)

                navigationButtons
                    .readGeometry(\.size.height, bindTo: $navigationButtonsHeight)

                NavHolder()
                    .alert(item: $viewModel.alert) { $0.alert }
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .animation(Constants.defaultAnimation, value: viewModel.step)
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
                Spacer()
                    .layoutPriority(1)

                // Making sure the header doesn't jump when changing the visibility of the fields
                ZStack {
                    headerText(title: title, subtitle: viewModel.subtitle)

                    headerText(title: "Title", subtitle: "Subtitle")
                        .hidden()
                }
                .animation(nil, value: title)
                .padding(.vertical, 0)
                .lineLimit(1)
                .layoutPriority(2)

                if viewModel.showQRCodeButton {
                    Button(action: viewModel.scanQRCode) {
                        Assets.qrCode.image
                            .renderingMode(.template)
                            .foregroundColor(Colors.Icon.primary1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .disabled(viewModel.updatingFees)
                    .layoutPriority(1)
                } else {
                    Spacer()
                        .layoutPriority(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private func headerText(title: String, subtitle: String?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            if let subtitle = subtitle {
                Text(subtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step {
        case .amount:
            SendAmountView(namespace: namespace, viewModel: viewModel.sendAmountViewModel)
        case .destination:
            SendDestinationView(namespace: namespace, viewModel: viewModel.sendDestinationViewModel, bottomSpacing: bottomGradientHeight)
        case .fee:
            SendFeeView(namespace: namespace, viewModel: viewModel.sendFeeViewModel, bottomSpacing: bottomGradientHeight)
        case .summary:
            SendSummaryView(namespace: namespace, viewModel: viewModel.sendSummaryViewModel, bottomSpacing: navigationButtonsHeight)
                .onAppear(perform: viewModel.onSummaryAppear)
                .onDisappear(perform: viewModel.onSummaryDisappear)
        case .finish(let sendFinishViewModel):
            SendFinishView(namespace: namespace, viewModel: sendFinishViewModel, bottomSpacing: navigationButtonsHeight)
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
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
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        LinearGradient(colors: [.clear, backgroundColor], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .frame(maxHeight: bottomGradientHeight)
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
        static let animationDuration: TimeInterval = 0.3
        static let defaultAnimation: Animation = .spring(duration: 0.3)
        static let backButtonAnimation: Animation = .easeOut(duration: 0.1)
        static let sectionContentAnimation: Animation = .easeOut(duration: animationDuration)
        static let auxiliaryViewTransition: AnyTransition = .offset(y: UIScreen.main.bounds.height).combined(with: .opacity)
        static let hintViewTransition: AnyTransition = .asymmetric(insertion: .offset(y: 20), removal: .identity).combined(with: .opacity)
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

struct SendView_Preview: PreviewProvider {
    static let card = FakeUserWalletModel.wallet3Cards

    static let viewModel = SendViewModel(
        walletName: card.userWalletName,
        walletModel: card.walletModelsManager.walletModels.first!,
        userWalletModel: card,
        transactionSigner: TransactionSignerMock(),
        sendType: .send,
        emailDataProvider: EmailDataProviderMock(),
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
