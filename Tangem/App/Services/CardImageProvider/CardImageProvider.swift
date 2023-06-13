//
//  CardImageProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemSdk
import Kingfisher

struct CardImageProvider {
    private static let cardArtworkCacheQueue = DispatchQueue(
        label: "com.tangem.CardImageProvider.cardArtworkCacheQueue",
        attributes: .concurrent
    )

    private static var _cardArtworkCache: [String: CardArtwork] = [:]
    private static var cardArtworkCache: [String: CardArtwork] {
        get {
            return cardArtworkCacheQueue.sync { _cardArtworkCache }
        }
        set {
            cardArtworkCacheQueue.async(flags: .barrier) { _cardArtworkCache = newValue }
        }
    }

    @Injected(\.cardImageLoader) private var imageLoader: CardImageLoaderProtocol

    private let supportsOnlineImage: Bool
    private let defaultImage = UIImage(named: "dark_card")!

    private let cardVerifier: OnlineCardVerifier
    private let kingfisherCache = KingfisherManager.shared.cache

    init(supportsOnlineImage: Bool = true) {
        self.supportsOnlineImage = supportsOnlineImage

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        let networkService = NetworkService(configuration: configuration)
        cardVerifier = OnlineCardVerifier(with: networkService)
    }

    func cardArtwork(for cardId: String) -> CardArtwork? {
        Self.cardArtworkCache[cardId]
    }
}

// MARK: - CardImageProviding

extension CardImageProvider: CardImageProviding {
    func loadImage(cardId: String, cardPublicKey: Data) -> AnyPublisher<CardImageResult, Never> {
        loadImage(cardId: cardId, cardPublicKey: cardPublicKey, artwork: nil)
    }

    func loadImage(cardId: String, cardPublicKey: Data, artwork: CardArtwork?) -> AnyPublisher<CardImageResult, Never> {
        guard supportsOnlineImage else {
            return Just(.embedded(defaultImage)).eraseToAnyPublisher()
        }

        let cardArtwork = artwork ?? cardArtwork(for: cardId) ?? .notLoaded

        return loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: cardArtwork)
            .replaceError(with: .embedded(defaultImage))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func loadTwinImage(for number: Int) -> AnyPublisher<CardImageResult, Never> {
        let cacheKey = "twin_\(number)"

        if let image = getImageFromCache(for: cacheKey) {
            return Just(.cached(image))
                .eraseToAnyPublisher()
        }

        return imageLoader.loadTwinImage(for: number)
            .handleEvents(receiveOutput: { image in
                cacheImage(image, for: cacheKey)
            })
            .map { .downloaded($0) }
            .replaceError(with: .embedded(defaultImage))
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CardImageProvider {
    func loadImage(cardId: String, cardPublicKey: Data, cardArtwork: CardArtwork) -> AnyPublisher<CardImageResult, Error> {
        if let number = getTwinNumberFor(for: cardId) {
            return loadTwinImage(for: number)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        if let cachedImage = getImageFromCache(for: cardId) {
            return .justWithError(output: .cached(cachedImage))
        }

        switch cardArtwork {
        case .noArtwork:
            return .justWithError(output: .embedded(defaultImage))
        case .notLoaded:
            return loadArtworkInfo(cardId: cardId, cardPublicKey: cardPublicKey)
                .tryMap {
                    loadImage(cardId: cardId, cardPublicKey: cardPublicKey, cardArtwork: $0)
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        case .artwork(let artworkInfo):
            return imageLoader
                .loadImage(cid: cardId, cardPublicKey: cardPublicKey, artworkInfoId: artworkInfo.id)
                .handleEvents(receiveOutput: { image in
                    cacheImage(image, for: cardId)
                })
                .map { .downloaded($0) }
                .eraseToAnyPublisher()
        }
    }

    func loadArtworkInfo(cardId: String, cardPublicKey: Data) -> AnyPublisher<CardArtwork, Never> {
        cardVerifier.getCardInfo(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { info in
                if let artwork = info.artwork {
                    return CardArtwork.artwork(artwork)
                } else {
                    return .noArtwork
                }
            }
            .handleEvents(receiveOutput: { cardArtwork in
                CardImageProvider.cardArtworkCache[cardId] = cardArtwork
            })
            .replaceError(with: CardArtwork.noArtwork)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getTwinNumberFor(for cardId: String) -> Int? {
        let prefix = String(cardId.prefix(4)).uppercased()

        return TwinCardSeries.allCases.first(where: {
            prefix.elementsEqual($0.rawValue.uppercased())
        })?.number
    }

    func cacheImage(_ image: UIImage, for key: String) {
        kingfisherCache.store(image, forKey: key)
    }

    func getImageFromCache(for key: String) -> UIImage? {
        if let cachedImage = kingfisherCache.memoryStorage.value(forKey: key) {
            return cachedImage
        }

        guard
            let diskImageData = try? kingfisherCache.diskStorage.value(forKey: key),
            let image = UIImage(data: diskImageData)
        else {
            return nil
        }
        kingfisherCache.memoryStorage.store(value: image, forKey: key)

        return image
    }
}
