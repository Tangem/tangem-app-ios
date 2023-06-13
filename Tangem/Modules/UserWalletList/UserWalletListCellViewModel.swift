//
//  UserWalletListCellViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class UserWalletListCellViewModel: ObservableObject {
    @Published var balance: String = UserWalletListCellViewModel.defaultBalanceValue
    @Published var numberOfTokens: String? = nil
    @Published var image: UIImage?
    @Published var isSelected = false
    @Published var isBalanceLoading = true
    @Published var hasError: Bool = false

    let userWalletModel: UserWalletModel
    let subtitle: String
    let isMultiWallet: Bool
    let didTapUserWallet: () -> Void
    let didEditUserWallet: () -> Void
    let didDeleteUserWallet: () -> Void
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
        cardImageProvider: CardImageProviding,
        didTapUserWallet: @escaping () -> Void,
        didEditUserWallet: @escaping () -> Void,
        didDeleteUserWallet: @escaping () -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.subtitle = subtitle
        self.isMultiWallet = isMultiWallet
        self.isSelected = isSelected
        self.cardImageProvider = cardImageProvider
        self.didTapUserWallet = didTapUserWallet
        self.didEditUserWallet = didEditUserWallet
        self.didDeleteUserWallet = didDeleteUserWallet

        bind()
        loadImage()

        if isMultiWallet {
            updateNumberOfTokens()
        }
    }

    func onAppear() {
        if !userWalletModel.userWallet.isLocked {
            userWalletModel.initialUpdate()
        }
    }

    func edit() {
        didEditUserWallet()
    }

    func delete() {
        didDeleteUserWallet()
    }

    private func bind() {
        userWalletModel.totalBalanceProvider.totalBalancePublisher()
            .sink { [unowned self] loadingValue in
                switch loadingValue {
                case .loading:
                    isBalanceLoading = true
                    balance = Self.defaultBalanceValue
                    hasError = false
                case .loaded(let value):
                    isBalanceLoading = false
                    let balanceFormatter = BalanceFormatter()
                    balance = balanceFormatter.formatFiatBalance(value.balance, formattingOptions: .defaultFiatFormattingOptions)
                    hasError = value.hasError
                }
            }
            .store(in: &bag)
    }

    private func updateNumberOfTokens() {
        let blockchainsCount = userWalletModel.getSavedEntries().count
        let allTokensCount = blockchainsCount + userWalletModel.getSavedEntries().reduce(0) { $0 + $1.tokens.count }

        numberOfTokens = Localization.tokenCount(allTokensCount)
    }

    private func loadImage() {
        let artwork: CardArtwork
        if let artworkInfo = userWallet.artwork {
            artwork = .artwork(artworkInfo)
        } else {
            artwork = .notLoaded
        }

        cardImageProvider.loadImage(cardId: userWallet.card.cardId, cardPublicKey: userWallet.card.cardPublicKey, artwork: artwork)
            .sink { [weak self] loadResult in
                guard let self else { return }

                image = scaleImage(loadResult.uiImage, newHeight: imageHeight * UIScreen.main.scale)
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

extension UserWalletListCellViewModel {
    private static let defaultBalanceValue = "$0,000.00"
}
