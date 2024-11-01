//
//  SendAmountView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel

    let transitionService: SendTransitionService
    let namespace: Namespace

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountContainer

            if viewModel.auxiliaryViewsVisible {
                segmentControl
            }
        }
        .id(viewModel.id)
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.auxiliaryViewsVisible)
        .transition(transitionService.transitionToAmountStep(isEditMode: viewModel.isEditMode))
        .onAppear(perform: viewModel.onAppear)
    }

    private var amountContainer: some View {
        VStack(spacing: 32) {
            walletInfoView
                .visible(viewModel.auxiliaryViewsVisible)

            amountContent
        }
        .defaultRoundedBackground(
            with: Colors.Background.action,
            geometryEffect: .init(
                id: namespace.names.amountContainer,
                namespace: namespace.id
            )
        )
    }

    private var walletInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.walletHeaderText)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.walletName, in: namespace.id)

            SensitiveText(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.walletBalance, in: namespace.id)
        }
        // Because the top padding have to be is 16 to the white background
        // But the bottom padding have to be is 12
        .padding(.top, 4)
    }

    private var amountContent: some View {
        VStack(spacing: 18) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )
            .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 6) {
                SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                    .initialFocusBehavior(.noFocus)
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.currentFieldOptions)
                    .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                    .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)

                bottomInfoText
            }
        }
    }

    private var bottomInfoText: some View {
        Group {
            switch viewModel.bottomInfoText {
            case .none:
                // Hold empty space
                Text(" ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            case .info(let string):
                Text(string)
                    .style(Fonts.Regular.caption1, color: Colors.Text.attention)
            case .error(let string):
                Text(string)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }

    private var segmentControl: some View {
        GeometryReader { proxy in
            HStack(spacing: 8) {
                SendCurrencyPicker(
                    data: viewModel.currencyPickerData,
                    useFiatCalculation: viewModel.isFiatCalculation.asBinding
                )

                MainButton(title: Localization.sendMaxAmount, style: .secondary) {
                    viewModel.userDidTapMaxAmount()
                }
                .frame(width: proxy.size.width / 3)
            }
        }
        .transition(transitionService.amountAuxiliaryViewTransition)
    }
}

extension SendAmountView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendAmountViewGeometryEffectNames
    }
}

/*
 struct SendAmountView_Previews: PreviewProvider {
     static let viewModel = SendAmountViewModel(
         inputModel: SendDependenciesBuilder (userWalletName: "Wallet", wallet: .mockETH).makeStakingAmountInput(),
         cryptoFiatAmountConverter: .init(),
         input: StakingAmountInputMock(),
         output: StakingAmountOutputMock()
     )

     @Namespace static var namespace

     static var previews: some View {
         ZStack {
             Colors.Background.tertiary.ignoresSafeArea()

             SendAmountView(
                 viewModel: viewModel,
                 namespace: .init(id: namespace, names: StakingViewNamespaceID())
             )
         }
     }
 }
 */
