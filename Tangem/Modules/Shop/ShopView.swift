//
//  ShopView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 08.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel

    private let sectionRowVerticalPadding = 12.0
    private let sectionCornerRadius = 18.0
    private let applePayCornerRadius = 18.0

    var body: some View {
        VStack(spacing: 0) {
            SheetDragHandler()
                .padding(.bottom, 12)

            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer()
                            .frame(maxHeight: .infinity)

                        cardStack
                            .layoutPriority(1)

                        Spacer()
                            .frame(maxHeight: .infinity)

                        Text(Localization.shopOneWallet)
                            .font(.system(size: 30, weight: .bold))

                        cardSelector

                        Spacer()
                            .frame(maxHeight: .infinity)

                        purchaseForm

                        buyButtons
                    }
                    .padding(.horizontal)
                    .frame(
                        minWidth: geometry.size.width,
                        maxWidth: geometry.size.width,
                        minHeight: geometry.size.height,
                        maxHeight: .infinity,
                        alignment: .top
                    )
                }
            }
        }
        .background(Color(UIColor.tangemBgGray).edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.didAppear)
        .alert(item: $viewModel.error) { $0.alert }
    }

    @ViewBuilder
    private var cardStack: some View {
        let secondCardOffset = 12.0
        let thirdCardOffset = 22.0

        Assets.Onboarding.walletCard.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(
                Color.underlyingCardBackground1
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .offset(x: 0, y: secondCardOffset)
            )
            .background(
                Color.underlyingCardBackground2
                    .cornerRadius(12)
                    .padding(.horizontal, 36)
                    .offset(x: 0, y: viewModel.showingThirdCard ? thirdCardOffset : secondCardOffset)
            )
            .padding(.bottom, thirdCardOffset)
            .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var cardSelector: some View {
        Picker("", selection: $viewModel.selectedBundle) {
            Text(Localization.cardLabelCardCount(3)).tag(ShopViewModel.Bundle.threeCards)
            Text(Localization.cardLabelCardCount(2)).tag(ShopViewModel.Bundle.twoCards)
        }
        .pickerStyle(.segmented)
        .frame(minWidth: 0, maxWidth: 250)
    }

    @ViewBuilder
    private var purchaseForm: some View {
        VStack(spacing: 0) {
            HStack {
                Assets.Shop.ticket.image
                TextField(Localization.shopIHaveAPromoCode, text: $viewModel.discountCode) { editing in
                    if !editing {
                        viewModel.didEnterDiscountCode()
                    }
                }
                .disableAutocorrection(true)
                .keyboardType(.alphabet)

                if viewModel.checkingDiscountCode {
                    ActivityIndicatorView(isAnimating: true, color: .tangemGrayDark)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, sectionRowVerticalPadding)

            Separator(height: 0.5, padding: 0)

            HStack {
                Text(Localization.shopTotal)

                Spacer()

                if let totalAmountWithoutDiscount = viewModel.totalAmountWithoutDiscount {
                    Text(totalAmountWithoutDiscount)
                        .strikethrough()
                }

                ZStack {
                    Text(viewModel.totalAmount)
                    Text("0")
                        .foregroundColor(.clear)
                }
                .font(.system(size: 22, weight: .bold))

                if viewModel.loadingProducts {
                    ActivityIndicatorView(isAnimating: true, color: .tangemGrayDark)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, sectionRowVerticalPadding)
        }
        .background(Color.white.cornerRadius(sectionCornerRadius))
        .padding(.bottom, 8)

        if let notification = viewModel.orderNotification {
            VStack {
                Text(notification)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.white.cornerRadius(sectionCornerRadius))
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var buyButtons: some View {
        if viewModel.canUseApplePay {
            applePayButton
                .frame(height: 46)
                .cornerRadius(applePayCornerRadius)

            Button {
                viewModel.openWebCheckout()
            } label: {
                Text(Localization.shopOtherPaymentMethods)
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite, layout: .flexibleWidth))
        } else {
            Button {
                viewModel.openWebCheckout()
            } label: {
                Text(viewModel.buyButtonText)
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
        }
    }

    @ViewBuilder
    private var applePayButton: some View {
        // Note that applePayButtonType has different values depending on canOrder
        // The button is not updated otherwise and it is not possible to change the type of PKPaymentButton on the fly
        if viewModel.canOrder {
            ApplePayButton(type: viewModel.applePayButtonType, action: viewModel.openApplePayCheckout)
        } else {
            ApplePayButton(type: viewModel.applePayButtonType, action: viewModel.openApplePayCheckout)
        }
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(viewModel: .init(coordinator: ShopCoordinator()))
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
