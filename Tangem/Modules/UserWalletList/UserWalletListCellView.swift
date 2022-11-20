//
//  UserWalletListCellView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class UserWalletListCellViewModel: ObservableObject {
    @Published var balance: String = "$0,000.00"
    @Published var numberOfTokens: String? = nil
    @Published var image: UIImage?
    @Published var isSelected = false
    @Published var isBalanceLoading = true

    let userWalletModel: UserWalletModel
    let subtitle: String
    let isMultiWallet: Bool
    let didTapUserWallet: () -> Void
    let totalBalanceProvider: TotalBalanceProviding
    let imageHeight = 30.0

    var userWallet: UserWallet { userWalletModel.userWallet }
    var userWalletId: Data { userWallet.userWalletId }
    var name: String { userWallet.name }
    var isUserWalletLocked: Bool { userWallet.isLocked }

    private let cardImageProvider: CardImageProviding

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        subtitle: String,
        isMultiWallet: Bool,
        isUserWalletLocked: Bool,
        isSelected: Bool,
        totalBalanceProvider: TotalBalanceProviding,
        cardImageProvider: CardImageProviding,
        didTapUserWallet: @escaping () -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.subtitle = subtitle
        self.isMultiWallet = isMultiWallet
        self.isSelected = isSelected
        self.totalBalanceProvider = totalBalanceProvider
        self.cardImageProvider = cardImageProvider
        self.didTapUserWallet = didTapUserWallet

        bind()
        loadImage()

        if isMultiWallet {
            updateNumberOfTokens()
        }
    }

    func bind() {
        totalBalanceProvider.totalBalancePublisher()
            .compactMap { $0.value }
            .sink { [unowned self] balance in
                self.balance = balance.balance.currencyFormatted(code: balance.currencyCode)
                self.isBalanceLoading = false
            }
            .store(in: &bag)
    }

    private func updateNumberOfTokens() {
        let blockchainsCount = userWalletModel.getSavedEntries().count
        let allTokensCount = blockchainsCount + userWalletModel.getSavedEntries().reduce(0, { $0 + $1.tokens.count })

        if allTokensCount == 0 {
            numberOfTokens = nil
        } else {
            numberOfTokens = String.localizedStringWithFormat("token_count".localized, allTokensCount)
        }
    }

    private func loadImage() {
        let artwork: CardArtwork
        if let artworkInfo = userWallet.artwork {
            artwork = .artwork(artworkInfo)
        } else {
            artwork = .notLoaded
        }

        cardImageProvider.loadImage(cardId: userWallet.card.cardId, cardPublicKey: userWallet.card.cardPublicKey, artwork: artwork)
            .sink { [unowned self] image in
                self.image = self.scaleImage(image, newHeight: self.imageHeight * UIScreen.main.scale)
            }
            .store(in: &bag)
    }

    private func scaleImage(_ image: UIImage, newHeight: CGFloat) -> UIImage {
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale

        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.draw(in: CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }
}

struct UserWalletListCellView: View {
    @ObservedObject private var viewModel: UserWalletListCellViewModel

    init(viewModel: UserWalletListCellViewModel) {
        self.viewModel = viewModel
    }

    private let selectionIconSize: CGSize = .init(width: 14, height: 14)
    private let selectionIconBorderWidth: Double = 2

    var body: some View {
        HStack(spacing: 12) {
            cardImage
                .overlay(selectionIcon.offset(x: 4, y: -4), alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.name)
                    .style(Fonts.Bold.subheadline, color: viewModel.isSelected ? Colors.Text.accent : Colors.Text.primary1)
                    .lineLimit(1)

                Text(viewModel.subtitle)
                    .style(Font.footnote, color: Colors.Text.tertiary)
            }

            Spacer()

            if !viewModel.isUserWalletLocked {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.balance)
                        .style(Font.subheadline, color: Colors.Text.primary1)
                        .skeletonable(isShown: viewModel.isBalanceLoading, radius: 6)

                    Text(viewModel.numberOfTokens ?? "")
                        .style(Font.footnote, color: Colors.Text.tertiary)
                }
            } else {
                lockIcon
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 67)
        .contentShape(Rectangle())
        .background(Colors.Background.primary)
        .onTapGesture {
            viewModel.didTapUserWallet()
        }
    }

    @ViewBuilder
    private var cardImage: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 50, minHeight: viewModel.imageHeight, maxHeight: viewModel.imageHeight)
        } else {
            Color.tangemGrayLight4
                .transition(.opacity)
                .opacity(0.5)
                .cornerRadius(3)
                .frame(width: 50, height: viewModel.imageHeight)
        }
    }

    @ViewBuilder
    private var selectionIcon: some View {
        if viewModel.isSelected {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: selectionIconSize.width, height: selectionIconSize.height)
                .foregroundColor(Colors.Text.accent)
                .background(
                    Colors.Background.primary
                        .clipShape(Circle())
                        .frame(size: selectionIconSize + CGSize(width: 2 * selectionIconBorderWidth, height: 2 * selectionIconBorderWidth))
                )
        }
    }

    @ViewBuilder
    private var lockIcon: some View {
        Assets.lock
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Colors.Background.secondary)
            .cornerRadius(10)
    }
}
