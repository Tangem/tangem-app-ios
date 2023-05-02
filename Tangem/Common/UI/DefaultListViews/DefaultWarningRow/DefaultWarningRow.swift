//
//  DefaultWarningRow.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRow: View {
    private let viewModel: DefaultWarningRowViewModel

    init(viewModel: DefaultWarningRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if let action = viewModel.action {
            Button(action: action) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            leftView

            VStack(alignment: .leading, spacing: 4) {
                if let title = viewModel.title {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(viewModel.subtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            rightView
        }
        .padding(.vertical, 16)
        .background(Colors.Background.primary)
        .contentShape(Rectangle())
        .cornerRadius(12)
    }

    @ViewBuilder
    private var leftView: some View {
        baseAdditionalView(type: viewModel.leftView)
            .padding(10)
            .background(Colors.Background.secondary)
            .cornerRadius(40)
    }

    @ViewBuilder
    private var rightView: some View {
        baseAdditionalView(type: viewModel.rightView)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(Colors.Button.secondary)
            .cornerRadius(10)
    }

    @ViewBuilder
    func baseAdditionalView(type: DefaultWarningRowViewModel.AdditionalViewType?) -> some View {
        switch type {
        case .none:
            EmptyView()
        case .icon(let image):
            image.image
                .resizable()
                .frame(width: 20, height: 20)
        case .loader:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                .frame(width: 20, height: 20)
        }
    }
}

struct DefaultWarningRow_Preview: PreviewProvider {
    static let viewModels: [DefaultWarningRowViewModel] = [
        DefaultWarningRowViewModel(
            title: "Enable biometric authentication",
            subtitle: "Not enough funds for fee on your Polygon wallet to create a transaction. Top up your Polygon wallet first.",
            leftView: .icon(Assets.attention)
        ), DefaultWarningRowViewModel(
            title: "Exchange rate has expired",
            subtitle: "Recalculate route",
            leftView: .icon(Assets.attention),
            rightView: .icon(Assets.refreshWarningIcon)
        ), DefaultWarningRowViewModel(
            title: "Exchange rate has expired",
            subtitle: "Recalculate route",
            leftView: .icon(Assets.attention),
            rightView: .loader
        ), DefaultWarningRowViewModel(
            title: "Give Permission",
            subtitle: "To continue you need to allow 1inch smart contracts to use your Dai",
            leftView: .icon(Assets.swappingLock)
        ), DefaultWarningRowViewModel(
            title: "Waiting",
            subtitle: "Transaction in progress...",
            leftView: .loader
        ),
    ]

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ForEach(viewModels) {
                    DefaultWarningRow(viewModel: $0)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                }
            }
        }
    }
}
