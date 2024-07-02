//
//  WalletSelectorItemView.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletSelectorItemView: View {
    @ObservedObject var viewModel: WalletSelectorItemViewModel

    private let maxImageWidth = 50.0

    var body: some View {
        Button {
            viewModel.onTapAction()
        } label: {
            contentButton
        }
    }

    // MARK: - Private Implementation

    private var contentButton: some View {
        HStack(spacing: 12) {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxImageWidth, minHeight: viewModel.imageHeight, maxHeight: viewModel.imageHeight)
            } else {
                SkeletonView()
                    .cornerRadius(3)
                    .frame(width: maxImageWidth, height: viewModel.imageHeight)
            }

            Text(viewModel.name)
                .lineLimit(1)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

            Spacer(minLength: 0)

            selectedCheckmark
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var selectedCheckmark: some View {
        VStack {
            if viewModel.isSelected {
                Assets.Checked.on.image
                    .frame(size: Constants.checkedSelectedIconSize)
            } else {
                Assets.Checked.off.image
                    .frame(size: Constants.checkedSelectedIconSize)
            }
        }
    }
}

extension WalletSelectorItemView {
    enum Constants {
        static let checkedSelectedIconSize = CGSize(bothDimensions: 24)
    }
}

#Preview {
    VStack {
        WalletSelectorItemView(viewModel: .init(
            userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
            name: FakeUserWalletModel.wallet3Cards.config.cardName,
            cardImagePublisher: FakeUserWalletModel.wallet3Cards.cardImagePublisher,
            isSelected: true,
            didTapWallet: { _ in }
        )
        )

        WalletSelectorItemView(viewModel: .init(
            userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
            name: FakeUserWalletModel.wallet3Cards.config.cardName,
            cardImagePublisher: FakeUserWalletModel.wallet3Cards.cardImagePublisher,
            isSelected: false,
            didTapWallet: { _ in }
        )
        )
    }
}
