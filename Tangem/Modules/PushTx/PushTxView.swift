//
//  PushTxView.swift
//  Tangem
//
//  Created by Andrew Son on 14/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct FilledInputView: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                .foregroundColor(Color.tangemGrayDark)
                .padding(.bottom, 4)
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.tangemGrayDark6)
            Separator()
        }
    }
}

struct PushTxView: View {
    @ObservedObject var viewModel: PushTxViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    HStack {
                        Text(Localization.commonPush)
                            .font(Font.system(size: 30.0, weight: .bold, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                        Spacer()
                    }
                    .padding(.bottom)
                    FilledInputView(title: Localization.sendDestinationHintAddress, text: viewModel.destination)
                        .opacity(0.6)
                    VStack(alignment: .leading) {
                        Text(Localization.pushTxAddressHint)
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemGrayDark)
                            .opacity(0.6)
                            .padding(.bottom, 4)
                        HStack {
                            Text(viewModel.previousTotal)
                                .foregroundColor(.tangemGrayDark6)
                                .opacity(0.6)
                            Spacer()
                            Button(action: {
                                viewModel.isFiatCalculation.toggle()
                            }) { HStack(alignment: .center, spacing: 8.0) {
                                Text(viewModel.currency)
                                    .font(Font.system(size: 38.0, weight: .light, design: .default))
                                    .foregroundColor(viewModel.canFiatCalculation ?
                                        Color.tangemBlue : Color.tangemBlue.opacity(0.5))
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                    .foregroundColor(viewModel.canFiatCalculation ?
                                        Color.tangemBlue : Color.tangemBlue.opacity(0.5))
                            }
                            }
                            .foregroundColor(.tangemBlue)
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!viewModel.canFiatCalculation)
                        }
                        .font(.system(size: 38, weight: .light))
                    }
                    .padding(.top, 15)

                    Separator()
                    HStack {
                        Spacer()
                        SensitiveText(
                            builder: Localization.commonBalance,
                            sensitive: viewModel.walletTotalBalanceFormatted
                        )
                        .font(Font.system(size: 13.0, weight: .medium, design: .default))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(Color.tangemGrayDark)
                    }
                    VStack(alignment: .leading) {
                        Text(Localization.sendNetworkFeeTitle)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                            .padding(.vertical, 8.0)
                        PickerView(
                            contents: [
                                Localization.sendFeePickerLow,
                                Localization.sendFeePickerNormal,
                                Localization.sendFeePickerPriority,
                            ],
                            selection: $viewModel.selectedFeeLevel
                        )
                        .padding(.vertical, 8.0)
                        Text(viewModel.amountHint?.message ?? " ")
                            .font(.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor((viewModel.amountHint?.isError ?? false) ?
                                Color.red : Color.tangemGrayDark)
                        Toggle(isOn: $viewModel.isFeeIncluded) {
                            Text(Localization.sendFeeIncludeDescription)
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemGrayDark6)
                        }
                    }
                    Spacer()
                    VStack(spacing: 8.0) {
                        AmountView(
                            label: Localization.sendAmountLabel,
                            labelColor: .tangemGrayDark6,
                            amountText: viewModel.amount
                        )

                        AmountView(
                            label: Localization.pushPreviousFee,
                            labelColor: .tangemGrayDark,
                            amountText: viewModel.previousFee
                        )
                        .opacity(0.6)
                        AmountView(
                            label: Localization.pushAdditionalFee,
                            labelColor: .tangemGrayDark,
                            isLoading: viewModel.isFeeLoading,
                            amountText: viewModel.additionalFee
                        )
                        Separator()

                        AmountView(
                            label: Localization.sendTotalLabel,
                            labelColor: .tangemGrayDark6,
                            labelFont: .system(size: 20, weight: .bold, design: .default),
                            amountText: viewModel.sendTotal,
                            amountScaleFactor: 0.5,
                            amountLineLimit: 1
                        )
                        HStack {
                            Spacer()
                            Text(viewModel.sendTotalSubtitle)
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.tangemGrayDark)
                        }
                    }
                    //                    WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                    //                        self.viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                    //                    })
                    //                    .fixedSize(horizontal: false, vertical: true)
                    //                    .padding(.bottom, 16)
                    HStack(alignment: .center, spacing: 8.0) {
                        Spacer()
                        MainButton(
                            title: Localization.commonSend,
                            icon: .leading(Assets.arrowRightMini),
                            isDisabled: !viewModel.isSendEnabled,
                            action: viewModel.onSend
                        )
                        .alert(item: $viewModel.sendError) { $0.alert }
                    }
                    .padding(.top, 16.0)
                }
                .padding()
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
}

struct PushTxView_Previews: PreviewProvider {
    static var previews: some View {
        PushTxView(viewModel: .init(
            transaction: .dummyTx(
                blockchain: .bitcoin(testnet: false),
                type: .coin,
                destinationAddress: "tb1qrvkydv7322e7fl9v58eqvn87tx2jtlpqaetz2n"
            ),
            blockchainNetwork: PreviewCard.ethereum.blockchainNetwork!,
            cardViewModel: PreviewCard.ethereum.cardModel,
            coordinator: PushTxCoordinator()
        ))
    }
}
