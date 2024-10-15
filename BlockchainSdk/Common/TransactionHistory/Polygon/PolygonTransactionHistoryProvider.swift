//
//  PolygonTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class PolygonTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
    Mapper.Response == PolygonTransactionHistoryResult
{
    private let mapper: Mapper
    private let networkProvider: NetworkProvider<PolygonTransactionHistoryTarget>
    private let targetConfiguration: PolygonTransactionHistoryTarget.Configuration

    private var page: TransactionHistoryIndexPage?
    private var hasReachedEnd = false

    init(
        mapper: Mapper,
        networkConfiguration: NetworkProviderConfiguration,
        targetConfiguration: PolygonTransactionHistoryTarget.Configuration
    ) {
        self.mapper = mapper
        self.networkProvider = .init(configuration: networkConfiguration)
        self.targetConfiguration = targetConfiguration
    }

    private func makeTarget(
        for request: TransactionHistory.Request,
        requestedPageNumber: Int
    ) -> PolygonTransactionHistoryTarget {
        let target: PolygonTransactionHistoryTarget.Target
        if let contractAddress = request.amountType.token?.contractAddress {
            target = .getTokenTransactionHistory(
                address: request.address,
                contract: contractAddress,
                page: requestedPageNumber,
                limit: request.limit
            )
        } else {
            target = .getCoinTransactionHistory(
                address: request.address,
                page: requestedPageNumber,
                limit: request.limit
            )
        }

        return PolygonTransactionHistoryTarget(configuration: targetConfiguration, target: target)
    }

    /// Provides exponential backoff with random jitter using standard formula `base * pow(2, retryAttempt) ± jitter`.
    private func makeRetryInterval(retryAttempt: Int) -> DispatchQueue.SchedulerTimeType.Stride {
        let retryJitter: TimeInterval = .random(in: Constants.retryJitterMinValue...Constants.retryJitterMaxValue)
        let retryIntervalSeconds = Constants.retryBaseValue * pow(2.0, TimeInterval(retryAttempt)) + retryJitter
        let retryIntervalNanoseconds = Int(retryIntervalSeconds * TimeInterval(NSEC_PER_SEC))

        return .init(DispatchTimeInterval.nanoseconds(retryIntervalNanoseconds))
    }

    private func loadTransactionHistory(
        request: TransactionHistory.Request,
        requestedPageNumber: Int?,
        retryAttempt: Int
    ) -> AnyPublisher<TransactionHistory.Response, Error> {
        return Deferred { [weak self] in
            Future { promise in
                if let requestedPageNumber {
                    promise(.success(requestedPageNumber))
                } else if let currentPageNumber = self?.page?.number {
                    promise(.success(currentPageNumber + 1))
                } else {
                    promise(.success(Constants.initialPageNumber))
                }
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { historyProvider, requestedPageNumber in
            return Just(request)
                .withWeakCaptureOf(historyProvider)
                .map { historyProvider, request in
                    return historyProvider.makeTarget(for: request, requestedPageNumber: requestedPageNumber)
                }
                .withWeakCaptureOf(historyProvider)
                .map { historyProvider, target in
                    return historyProvider
                        .networkProvider
                        .requestPublisher(target)
                        .filterSuccessfulStatusAndRedirectCodes()
                        .map(PolygonTransactionHistoryResult.self)
                        .eraseError()
                }
                .switchToLatest()
                .withWeakCaptureOf(historyProvider)
                .handleEvents(receiveOutput: { historyProvider, _ in
                    historyProvider.page = TransactionHistoryIndexPage(number: requestedPageNumber)
                })
                .tryMap { historyProvider, result in
                    let transactionRecords = try historyProvider
                        .mapper
                        .mapToTransactionRecords(result, walletAddress: request.address, amountType: request.amountType)
                        .filter { record in
                            historyProvider.shouldBeIncludedInHistory(
                                amountType: request.amountType,
                                record: record
                            )
                        }
                    return TransactionHistory.Response(records: transactionRecords)
                }
                .tryCatch { [weak historyProvider] error in
                    return historyProvider
                        .publisher
                        .flatMap { historyProvider in
                            return historyProvider.handleLoadTransactionHistoryError(
                                error,
                                request: request,
                                requestedPageNumber: requestedPageNumber,
                                retryAttempt: retryAttempt
                            )
                        }
                }
        }
        .eraseToAnyPublisher()
    }

    private func handleLoadTransactionHistoryError(
        _ error: Error,
        request: TransactionHistory.Request,
        requestedPageNumber: Int,
        retryAttempt: Int
    ) -> AnyPublisher<TransactionHistory.Response, Error> {
        guard let error = error as? PolygonScanAPIError else {
            return .anyFail(error: error)
        }

        switch error {
        case .maxRateLimitReached where retryAttempt < Constants.maxRetryCount:
            let nextRetryAttempt = retryAttempt + 1
            let retryInterval = makeRetryInterval(retryAttempt: nextRetryAttempt)

            return Just(())
                .delay(for: retryInterval, scheduler: DispatchQueue.main)
                .withWeakCaptureOf(self)
                .flatMap { historyProvider, _ in
                    return historyProvider.loadTransactionHistory(
                        request: request,
                        requestedPageNumber: requestedPageNumber,
                        retryAttempt: nextRetryAttempt
                    )
                }
                .eraseToAnyPublisher()
        case .endOfTransactionHistoryReached:
            hasReachedEnd = true
            return .justWithError(output: TransactionHistory.Response(records: []))
        case .unknown, .maxRateLimitReached:
            return .anyFail(error: error)
        }
    }
}

// MARK: - TransactionHistoryProvider protocol conformance

extension PolygonTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        page == nil || !hasReachedEnd
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        return loadTransactionHistory(request: request, requestedPageNumber: nil, retryAttempt: 0)
    }

    func reset() {
        mapper.reset()
        page = nil
        hasReachedEnd = false
    }
}

// MARK: - Constants

private extension PolygonTransactionHistoryProvider {
    enum Constants {
        // - Note: Tx history API has 1-based indexing (not 0-based indexing)
        static var initialPageNumber: Int { 1 }
        static var maxRetryCount: Int { 3 }
        static var retryBaseValue: TimeInterval { 1.0 }
        static var retryJitterMinValue: TimeInterval { -0.5 }
        static var retryJitterMaxValue: TimeInterval { 0.5 }
    }
}
