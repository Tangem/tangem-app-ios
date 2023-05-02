//
//  BalanceAddressView.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct BalanceAddressView: View {
    @ObservedObject var walletModel: WalletModel
    var amountType: Amount.AmountType
    var isRefreshing: Bool
    let showExplorerURL: (URL?) -> Void
    @State private var selectedAddressIndex: Int = 0

    var blockchainText: String {
        if walletModel.state.isNoAccount {
            return Localization.walletErrorNoAccount
        }

        if walletModel.state.isBlockchainUnreachable {
            return Localization.walletBalanceBlockchainUnreachable
        }

        if walletModel.wallet.hasPendingTx(for: amountType) {
            return Localization.walletBalanceTxInProgress
        }

        if walletModel.state.isLoading {
            return Localization.walletBalanceLoading
        }

        return Localization.walletBalanceVerified
    }

    var image: String {
        walletModel.state.errorDescription == nil
            && !walletModel.wallet.hasPendingTx(for: amountType)
            && !walletModel.state.isLoading ? "checkmark.circle" : "exclamationmark.circle"
    }

    var showAddressSelector: Bool {
        return walletModel.wallet.addresses.count > 1
    }

    var accentColor: Color {
        if walletModel.state.errorDescription == nil,
           !walletModel.wallet.hasPendingTx(for: amountType),
           !walletModel.state.isLoading {
            return .tangemGreen
        }
        return .tangemWarning
    }

    var balance: String {
        walletModel.getBalance(for: amountType)
    }

    var fiatBalance: String {
        walletModel.getFiatBalance(for: amountType)
    }

    var isSkeletonShown: Bool {
        walletModel.state.isLoading && !isRefreshing
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    if let errorDescription = walletModel.state.errorDescription {
                        Text(errorDescription)
                            .layoutPriority(1)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(accentColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(fiatBalance)
                            .font(Font.system(size: 20.0, weight: .bold, design: .default))
                            .foregroundColor(Color.tangemGrayDark6)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .truncationMode(.middle)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .skeletonable(isShown: isSkeletonShown, size: CGSize(width: 70, height: 20), radius: 6)
                        Text(balance)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.tangemGrayDark)
                            .skeletonable(isShown: isSkeletonShown, size: CGSize(width: 100, height: 14), radius: 6)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                        Image(systemName: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(accentColor)
                            .frame(width: 10.0, height: 10.0)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        VStack(alignment: .leading) {
                            Text(blockchainText)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(accentColor)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                TokenIconView(viewModel: .init(with: amountType, blockchain: walletModel.wallet.blockchain))
                    .saturation(walletModel.isTestnet ? 0 : 1)
            }

            if showAddressSelector {
                PickerView(contents: walletModel.addressNames, selection: $selectedAddressIndex)
                    .padding(.vertical, 16)
            }

            GeometryReader { geometry in
                VStack {
                    HStack(alignment: .top, spacing: 8) {
                        Image(uiImage: QrCodeGenerator.generateQRCode(from: walletModel.shareAddressString(for: selectedAddressIndex)))
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fill)
                            .frame(width: geometry.size.width * 0.3)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(walletModel.displayAddress(for: selectedAddressIndex))
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .lineLimit(3)
                                .truncationMode(.middle)
                                .foregroundColor(Color.tangemGrayDark)
                                .fixedSize(horizontal: false, vertical: true)

                            ExploreButton(
                                url: walletModel.exploreURL(for: selectedAddressIndex, token: amountType.token),
                                showExplorerURL: showExplorerURL
                            )

                            HStack {
                                RoundedRectButton(
                                    action: { copyAddress() },
                                    systemImageName: "doc.on.clipboard",
                                    title: Localization.commonCopy,
                                    withVerification: true
                                )
                                .accessibility(label: Text(Localization.voiceOverCopyAddress))

                                RoundedRectButton(
                                    action: { showShareSheet() },
                                    systemImageName: "square.and.arrow.up",
                                    title: Localization.commonShare
                                )
                                .accessibility(label: Text(Localization.voiceOverShareAddress))
                            }
                        }
                        .frame(width: geometry.size.width * 0.7)
                    }
                }
            }
            .frame(height: 86)
            .padding(.bottom, 16)

            Text(walletModel.getQRReceiveMessage(for: amountType))
                .font(.system(size: 16, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemGrayDark)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(6)
    }

    func showShareSheet() {
        Analytics.log(.buttonShareAddress)
        let address = walletModel.displayAddress(for: selectedAddressIndex)
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }

    private func copyAddress() {
        Analytics.log(.buttonCopyAddress)
        UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex)
    }
}

struct BalanceAddressView_Previews: PreviewProvider {
    static var walletModel: WalletModel {
        let vm = PreviewCard.stellar.cardModel.walletModels.first!
        vm.state = .failed(error: "Failed to load. Internet connection is unnreachable")
        vm.state = .idle
        return vm
    }

    static var previews: some View {
        ZStack {
            Color.gray
            ScrollView {
                BalanceAddressView(
                    walletModel: walletModel, amountType: .coin, isRefreshing: false, showExplorerURL: { _ in }
                )
                .padding()
            }
        }
        .previewGroup(devices: [.iPhone7])
    }
}
