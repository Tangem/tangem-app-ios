//
//  CardImageLoader.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIImage
import Combine
import TangemSdk

class CardImageLoader {
    private let networkService: NetworkService
    private let sessionConfiguration: URLSessionConfiguration

    init() {
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 10
        sessionConfiguration.timeoutIntervalForResource = 30
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        networkService = .init(configuration: sessionConfiguration)
    }

    deinit {
        AppLog.debug(self)
    }

    private func loadImage(at endpoint: NetworkEndpoint) -> AnyPublisher<UIImage, Error> {
        networkService
            .requestPublisher(endpoint)
            .subscribe(on: DispatchQueue.global())
            .map { UIImage(data: $0) }
            .replaceNil(with: ImageError.mapFailed)
            .eraseToAnyPublisher()
    }

    private func loadImage(by name: String) -> AnyPublisher<UIImage, Error> {
        URLSession(configuration: sessionConfiguration)
            .dataTaskPublisher(for: URL(string: "https://app.tangem.com/cards/\(name).png")!)
            .subscribe(on: DispatchQueue.global())
            .map { UIImage(data: $0.0) }
            .replaceNil(with: ImageError.mapFailed)
            .eraseToAnyPublisher()
    }
}

extension CardImageLoader: CardImageLoaderProtocol {
    func loadImage(cid: String, cardPublicKey: Data, artworkInfoId: String) -> AnyPublisher<UIImage, Error> {
        let endpoint = TangemEndpoint.artwork(
            cid: cid,
            cardPublicKey: cardPublicKey,
            artworkId: artworkInfoId
        )

        return loadImage(at: endpoint)
    }

    func loadTwinImage(for number: Int) -> AnyPublisher<UIImage, Error> {
        let imageName = number == 1 ? "card_tg085" : "card_tg086"
        return loadImage(by: imageName)
    }
}

private enum ImageError: Error {
    case nothingToLoad
    case mapFailed
    case badNdef
}

// can't move it out from here due to compile error
extension Publisher where Output == String {
    func replaceEmptyString(with error: Error) -> AnyPublisher<String, Error> {
        tryMap { string -> String in
            if string.isEmpty {
                throw error
            }

            return string
        }
        .eraseToAnyPublisher()
    }
}

public extension Publisher {
    func replaceNil<T>(with error: Error) -> Publishers.TryMap<Self, T> where Self.Output == T? {
        tryMap { output -> T in
            if let output = output {
                return output
            }

            throw error
        }
    }
}
