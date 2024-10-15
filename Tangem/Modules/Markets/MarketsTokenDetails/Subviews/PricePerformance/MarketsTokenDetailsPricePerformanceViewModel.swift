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
        $selectedInterval
            .withWeakCaptureOf(self)
            .sink { value in
                let weakSelf = value.0
                let interval = value.1

                Analytics.log(
                    event: .marketsChartButtonPeriod,
                    params: [
                        .token: weakSelf.tokenSymbol.uppercased(),
                        .period: interval.analyticsParameterValue,
                        .source: Analytics.MarketsIntervalTypeSourceType.price.rawValue,
                    ]
                )
            }
            .store(in: &bag)

        currentPricePublisher
            .combineLatest($selectedInterval)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { value in
                let weakSelf = value.0
                let (currentPrice, interval) = value.1

                weakSelf.updateProgressUI(currentPrice: currentPrice, selectedInterval: interval)
            })
            .store(in: &bag)
    }

    private func updateProgressUI(currentPrice: Decimal, selectedInterval: MarketsPriceIntervalType) {
        guard
            let performanceData = pricePerformanceData[selectedInterval],
            let lowPrice = performanceData.lowPrice,
            let highPrice = performanceData.highPrice
        else {
            pricePerformanceProgress = 0
            lowValue = priceFormatter.formatPrice(nil)
            highValue = priceFormatter.formatPrice(nil)
            return
        }

        lowValue = priceFormatter.formatPrice(lowPrice)
        highValue = priceFormatter.formatPrice(highPrice)
        let decimalProgress = Math().inverseLerp(from: lowPrice, to: highPrice, value: currentPrice) as NSDecimalNumber
        pricePerformanceProgress = CGFloat(decimalProgress.doubleValue)
    }
}
