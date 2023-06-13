//
//  BalanceView.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk

struct TokenBalanceView: View {
    var tokenViewModel: TokenBalanceViewModel

    var body: some View {
        VStack {
            HStack {
                Text(tokenViewModel.name)
                Spacer()
                Text(tokenViewModel.balance)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.tangemGrayDark6)
            .padding(.bottom, 2)
            HStack {
                Spacer()
                Text(tokenViewModel.fiatBalance)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.tangemGrayDark)
            }
        }
        .padding(8)
        .background(Color.tangemGrayLight6)
        .cornerRadius(6)
    }
}

struct BalanceView: View {
    var balanceViewModel: BalanceViewModel

    var blockchainText: String {
        if balanceViewModel.state.isLoading {
            return Localization.walletBalanceLoading
        }

        if balanceViewModel.state.errorDescription != nil {
            return Localization.walletBalanceBlockchainUnreachable
        }

        if balanceViewModel.hasTransactionInProgress {
            return Localization.walletBalanceTxInProgress
        }

        return Localization.walletBalanceVerified
    }

    var accentColor: Color {
        if balanceViewModel.state.errorDescription == nil,
           !balanceViewModel.hasTransactionInProgress,
           !balanceViewModel.state.isLoading {
            return .tangemGreen
        }
        return .tangemWarning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 16)

            HStack {
                Text(balanceViewModel.name)
                Spacer()
                Text(balanceViewModel.fiatBalance)
                    .multilineTextAlignment(.trailing)
                    .truncationMode(.middle)
            }
            .font(Font.system(size: 20.0, weight: .bold, design: .default))
            .foregroundColor(Color.tangemGrayDark6)
            .minimumScaleFactor(0.8)
            .lineLimit(2)
            .padding(.horizontal, 24.0)
            .padding(.bottom, 8)
            .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 5.0) {
                Image(systemName: balanceViewModel.state.errorDescription == nil && !balanceViewModel.hasTransactionInProgress ? "checkmark.circle" : "exclamationmark.circle")
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
                    if balanceViewModel.state.errorDescription != nil {
                        Text(balanceViewModel.state.errorDescription!)
                            .layoutPriority(1)
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(accentColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Text(balanceViewModel.balanceFormatted)
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                    .lineLimit(1)
                    .foregroundColor(Color.tangemGrayDark)
            }
            .padding(.bottom, 16.0)
            .padding(.horizontal, 24.0)

            if let tokenViewModel = balanceViewModel.tokenBalanceViewModel {
                TokenBalanceView(tokenViewModel: tokenViewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(6.0)
    }
}

struct BalanceView_Previews: PreviewProvider {
    static let token =
        TokenBalanceViewModel(
            name: "SushiSwap",
            balance: "163.7425436",
            fiatBalance: "$ 2241.31"
        )

    static var previews: some View {
        ZStack {
            Color.tangemBgGray
            VStack {
                BalanceView(
                    balanceViewModel: BalanceViewModel(
                        hasTransactionInProgress: false,
                        state: .idle,
                        name: "Ethereum smart contract token",
                        fiatBalance: "$3.45",
                        balance: "0.00000348573986753845001 BTC",
                        tokenBalanceViewModel: token
                    )
                )
                .padding(.horizontal, 16)

                BalanceView(
                    balanceViewModel: BalanceViewModel(
                        hasTransactionInProgress: false,
                        state: .loading,
                        name: "Ethereum smart contract token",
                        fiatBalance: "$3.45",
                        balance: "0.00000348573986753845001 BTC",
                        tokenBalanceViewModel: token
                    )
                )
                .padding(.horizontal, 16)

                BalanceView(
                    balanceViewModel: BalanceViewModel(
                        hasTransactionInProgress: false,
                        state: .failed(error: "The internet connection appears to be offline. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description. Very very very long error description"),
                        name: "Ethereum smart contract token",
                        fiatBalance: " ",
                        balance: " ",
                        tokenBalanceViewModel: token
                    )
                )
                .padding(.horizontal, 16)

                BalanceView(
                    balanceViewModel: BalanceViewModel(
                        hasTransactionInProgress: true,
                        state: .idle,
                        name: "Bitcoin token",
                        fiatBalance: "5 USD",
                        balance: "10 BTCA",
                        tokenBalanceViewModel: token
                    )
                )
                .padding(.horizontal, 16)
            }
        }
    }
}
