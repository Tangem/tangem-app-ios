//
//  CardImageLoaderProtocol.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIImage
import Combine
import TangemSdk

protocol CardImageLoaderProtocol {
    func loadImage(cid: String, cardPublicKey: Data, artworkInfoId: String) -> AnyPublisher<UIImage, Error>
    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Error>
}

private struct CardImageLoaderKey: InjectionKey {
    static var currentValue: CardImageLoaderProtocol = CardImageLoader()
}

extension InjectedValues {
    var cardImageLoader: CardImageLoaderProtocol {
        get { Self[CardImageLoaderKey.self] }
        set { Self[CardImageLoaderKey.self] = newValue }
    }
}
