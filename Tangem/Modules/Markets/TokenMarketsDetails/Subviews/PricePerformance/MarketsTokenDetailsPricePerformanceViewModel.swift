//
//  MarketsTokenDetailsPricePerformanceViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 11/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsTokenDetailsPricePerformanceViewModel: ObservableObject {
    @Published var selectedInterval: MarketsPriceIntervalType = .day
    @Published var pricePerformanceProgress: CGFloat = 0.5
    @Published var lowValue: String = ""
    @Published var highValue: String = ""

    let intervalOptions: [MarketsPriceIntervalType] = [.day, .month, .all]

    private let tokenSymbol: String
    private let pricePerformanceData: [MarketsPriceIntervalType: MarketsPricePerformanceData]
    private let currentPricePublisher: AnyPublisher<Decimal, Never>
    private let priceFormatter = MarketsTokenPriceFormatter()

    private var bag = Set<AnyCancellable>()

    init(
        tokenSymbol: String,
        pricePerformanceData: [MarketsPriceIntervalType: MarketsPricePerformanceData],
        currentPricePublisher: AnyPublisher<Decimal, Never>
    ) {
        self.tokenSymbol = tokenSymbol
        self.pricePerformanceData = pricePerformanceData
        self.currentPricePublisher = currentPricePublisher

        bind()
    }

    private func bind() {
        currentPricePublisher
            .combineLatest($selectedInterval)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { value in
                let weakSelf = value.0
                let (currentPrice, interval) = value.1

                Analytics.log(
                    event: .marketsButtonPeriod,
                    params: [
                        .token: weakSelf.tokenSymbol,
                        .period: interval.rawValue,
                        .source: Analytics.MarketsIntervalTypeSourceType.price.rawValue,
                    ]
                )

                weakSelf.updateProgressUI(currentPrice: currentPrice, selectedInterval: interval)
            })
            .store(in: &bag)
    }

    private func updateProgressUI(currentPrice: Decimal, selectedInterval: MarketsPriceIntervalType) {
        guard let performanceData = pricePerformanceData[selectedInterval] else {
            return
        }

        let decimalProgress = Math().inverseLerp(from: performanceData.lowPrice, to: performanceData.highPrice, value: currentPrice) as NSDecimalNumber
        pricePerformanceProgress = CGFloat(decimalProgress.doubleValue)
        lowValue = priceFormatter.formatPrice(performanceData.lowPrice)
        highValue = priceFormatter.formatPrice(performanceData.highPrice)
    }
}
