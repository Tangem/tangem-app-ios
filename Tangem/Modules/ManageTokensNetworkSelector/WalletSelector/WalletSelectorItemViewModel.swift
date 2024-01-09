//
//  WalletSelectorItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class WalletSelectorItemViewModel: ObservableObject, Identifiable {
    @Published var image: UIImage? = nil
    @Published var isSelected: Bool = false

    let userWalletId: UserWalletId
    let name: String

    let cardImagePublisher: AnyPublisher<CardImageResult, Never>
    let didTapWallet: (UserWalletId) -> Void

    let imageHeight = 30.0

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        name: String,
        cardImagePublisher: AnyPublisher<CardImageResult, Never>,
        isSelected: Bool,
        didTapWallet: @escaping (UserWalletId) -> Void
    ) {
        self.userWalletId = userWalletId
        self.name = name
        self.isSelected = isSelected
        self.cardImagePublisher = cardImagePublisher
        self.didTapWallet = didTapWallet

        loadImage()
    }

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
