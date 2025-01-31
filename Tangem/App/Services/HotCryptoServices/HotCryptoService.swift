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

    private var hotCryptoItemsSubject = CurrentValueSubject<[HotCryptoToken], Never>([])
    private var currencyCodeBag: AnyCancellable?
    private var loadTask: Task<Void, Never>?

    init() {
        bind()
    }

    func bind() {
        // Don't uses .dropFirst(), because loading required when we create instance of service
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
        loadTask?.cancel()
        
        loadTask = Task { [weak self] in
            guard
                let self,
                let fetchedHotCryptoItems = try? await tangemApiService.loadHotCrypto(
                    requestModel: .init(currency: AppSettings.shared.selectedCurrencyCode)
                )
            else {
                return
            }
            
            guard !Task.isCancelled else { return }

            hotCryptoItemsSubject.send(fetchedHotCryptoItems.tokens.map { .init(from: $0) })
        }
    }
}
