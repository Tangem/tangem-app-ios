//
//  HotCryptoService.swift
//  TangemApp
//
//  Created by GuitarKitty on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol HotCryptoService: AnyObject {
    var hotCryptoItemsPublisher: AnyPublisher<[HotCryptoToken], Never> { get }

    func loadHotCrypto(_ currencyCode: String)
}

final class CommonHotCryptoService {
    // MARK: - Dependencies

    @Injected(\.tangemApiService)
    private var tangemApiService: TangemApiService

    // MARK: - Private properties

    private var isHotTokensNotLoaded = true
    private var hotCryptoItemsSubject = CurrentValueSubject<[HotCryptoToken], Never>([])
    private var currencyCodeBag: AnyCancellable?

    init() {
        bind()
    }

    func bind() {
        currencyCodeBag = AppSettings.shared.$selectedCurrencyCode
            .withWeakCaptureOf(self)
            .receiveValue { service, currencyCode in
                service.loadHotCrypto(currencyCode)
            }
    }
}

// MARK: - HotCryptoService

extension CommonHotCryptoService: HotCryptoService {
    var hotCryptoItemsPublisher: AnyPublisher<[HotCryptoToken], Never> {
        hotCryptoItemsSubject.eraseToAnyPublisher()
    }

    func loadHotCrypto(_ currencyCode: String) {
        Task {
            guard
                let fetchedHotCryptoItems = try? await tangemApiService.loadHotCrypto(
                    requestModel: .init(currency: AppSettings.shared.selectedCurrencyCode)
                )
            else {
                return
            }

            hotCryptoItemsSubject.send(fetchedHotCryptoItems.tokens.map { .init(from: $0) })
        }
    }
}
