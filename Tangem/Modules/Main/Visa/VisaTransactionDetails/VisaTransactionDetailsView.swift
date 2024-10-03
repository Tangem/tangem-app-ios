//
//  VisaTransactionDetailsView.swift
//  Tangem
//
//  Created by Andrew Son on 26/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaTransactionDetailsView: View {
    @ObservedObject var viewModel: VisaTransactionDetailsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    fiatTransactionContent

                    ForEach(viewModel.cryptoRequests, id: \.commonTransactionInfo.transactionId) { requestInfo in
                        cryptoRequestView(requestInfo)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(Text("Transaction details"))
            .navigationBarTitleDisplayMode(.inline)
            .background(Colors.Background.tertiary.ignoresSafeArea())
        }
    }

    private var fiatTransactionContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Transaction")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()
            }

            VStack(spacing: 0) {
                commonTransactionInfoView(viewModel.fiatTransactionInfo)
                merchantInfo
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var merchantInfo: some View {
        VStack(spacing: 0) {
            recordLine(title: "Merchant name", value: viewModel.merchantName)
            recordLine(title: "Merchant city", value: viewModel.merchantCity)
            recordLine(title: "Merchant country code", value: viewModel.merchantCountryCode)
            recordLine(title: "Merchant category code", value: viewModel.merchantCategoryCode)
        }
    }

    private func cryptoRequestView(_ info: CryptoRequestInfo) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Transaction request")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if let exploreAction = info.exploreAction {
                    Button(action: exploreAction, label: {
                        HStack(spacing: 4) {
                            Assets.compassExplore.image
                                .foregroundColor(Colors.Icon.informative)

                            Text(Localization.commonExplore)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                    })
                }
            }

            VStack(spacing: 0) {
                commonTransactionInfoView(info.commonTransactionInfo)

                recordLine(title: "Error code", value: info.errorCode)
                recordLine(title: "Tx hash", value: info.hash)
                recordLine(title: "Tx status", value: info.status)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func commonTransactionInfoView(_ info: CommonTransactionInfo) -> some View {
        VStack(spacing: 0) {
            recordLine(title: info.idTitle.rawValue, value: info.transactionId)
            recordLine(title: "Date", value: info.date)
            recordLine(title: "Type", value: info.type)
            recordLine(title: "Status", value: info.status)
            recordLine(title: "Blockchain amount", value: info.blockchainAmount)
            recordLine(title: "Blockchain fee", value: info.blockchainFee)
            recordLine(title: "Transaction Amount", value: info.transactionAmount)
            recordLine(title: "Currency code", value: info.currencyCode)
        }
    }

    private func recordLine(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .frame(minWidth: 80, alignment: .leading)

            Spacer(minLength: 10)

            Text(value)
                .multilineTextAlignment(.trailing)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
        .padding(.vertical, 8)
    }
}

extension VisaTransactionDetailsView {
    struct CommonTransactionInfo {
        let idTitle: IDTitle
        let transactionId: String
        let date: String
        let type: String
        let status: String
        let blockchainAmount: String
        let blockchainFee: String
        let transactionAmount: String
        let currencyCode: String

        enum IDTitle: String {
            case id = "ID"
            case requestId = "Request ID"
        }
    }

    struct CryptoRequestInfo {
        let commonTransactionInfo: CommonTransactionInfo
        let errorCode: String
        let hash: String
        let status: String
        let exploreAction: (() -> Void)?
    }
}

#Preview {
    VisaTransactionDetailsView(viewModel: .uiMock)
}
