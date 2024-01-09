//
//  SendFinishView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFinishView: View {
    let height = 150.0
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendFinishViewModel

    var body: some View {
        VStack(spacing: 20) {
            header

            amountSummary

            destinationSummary

            feeSummary

            Spacer()

            bottomButtons
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 0) {
            Assets.inProgress
                .image

            Text(Localization.sentTransactionSentTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .padding(.top, 18)

            Text(viewModel.transactionTime ?? "")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var amountSummary: some View {
        Color.clear
            .frame(maxHeight: height)
            .border(Color.green, width: 5)
            .overlay(
                VStack {
                    HStack {
                        Text(viewModel.amountText)
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
                .padding()
            )
            .matchedGeometryEffect(id: "amount", in: namespace)
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
    }

    @ViewBuilder
    private var destinationSummary: some View {
        Color.clear
            .frame(maxHeight: height)
            .border(Color.purple, width: 5)
            .overlay(
                VStack(alignment: .leading) {
                    HStack {
                        Text(viewModel.destinationText)
                            .lineLimit(1)
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
                .padding()
            )
            .matchedGeometryEffect(id: "dest", in: namespace)
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
    }

    @ViewBuilder
    private var feeSummary: some View {
        Color.clear
            .frame(maxHeight: height)
            .border(Color.blue, width: 5)
            .overlay(
                VStack(alignment: .leading) {
                    HStack {
                        Text(viewModel.feeText)
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
                .padding()
            )
            .transition(.identity)
            .matchedGeometryEffect(id: "fee", in: namespace)
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 10) {
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

            MainButton(
                title: Localization.commonClose,
                action: viewModel.close
            )
        }
    }
}

struct SendFinishView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendFinishView(namespace: namespace, viewModel: SendFinishViewModel(input: SendFinishViewModelInputMock())!)
    }
}
