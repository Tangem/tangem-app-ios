//
//  WalletSelectorItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class WalletSelectorItemViewModel: ObservableObject, Identifiable {
    @Published var image: UIImage? = nil
    @Published var isSelected: Bool = false

    let name: String
    let imageHeight = 30.0
    let userWalletId: UserWalletId

    private let cardImagePublisher: AnyPublisher<CardImageResult, Never>

    private var bag: Set<AnyCancellable> = []
    private var didTapWallet: ((UserWalletId) -> Void)?

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        name: String,
        cardImagePublisher: AnyPublisher<CardImageResult, Never>,
        isSelected: Bool,
        didTapWallet: ((UserWalletId) -> Void)?
    ) {
        self.userWalletId = userWalletId
        self.name = name
        self.isSelected = isSelected
        self.cardImagePublisher = cardImagePublisher
        self.didTapWallet = didTapWallet

        loadImage()
    }

    func onTapAction() {
        didTapWallet?(userWalletId)
    }

    // MARK: - Private Implementation

    private func loadImage() {
        cardImagePublisher
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
