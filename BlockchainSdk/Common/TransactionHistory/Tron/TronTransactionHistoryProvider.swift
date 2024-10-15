//
//  TronTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 28.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class TronTransactionHistoryProvider<Mapper> where
    Mapper: TransactionHistoryMapper,
    Mapper: BlockBookTransactionHistoryTotalPageCountExtractor,
    Mapper.Response == BlockBookAddressResponse
{
    private let blockBookProvider: BlockBookUtxoProvider
    private let mapper: Mapper

    private var page: TransactionHistoryIndexPage?
    private var totalPageCount: Int = 0

    init(
        blockBookProvider: BlockBookUtxoProvider,
        mapper: Mapper
    ) {
        self.blockBookProvider = blockBookProvider
        self.mapper = mapper
    }
}

// MARK: - TransactionHistoryProvider protocol conformance

extension TronTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        page == nil || (page?.number ?? Constants.initialPageNumber) < totalPageCount
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        let requestedPageNumber: Int
        if let page = page {
            requestedPageNumber = page.number + 1
        } else {
            requestedPageNumber = Constants.initialPageNumber
        }

        return Just(
            BlockBookTarget.AddressRequestParameters(
                page: requestedPageNumber,
                pageSize: request.limit,
                details: [.txslight],
                filterType: .init(amountType: request.amountType)
            )
        )
        .withWeakCaptureOf(self)
        .flatMap { historyProvider, parameters in
            return historyProvider
                .blockBookProvider
                .addressData(address: request.address, parameters: parameters)
        }
        .withWeakCaptureOf(self)
        .tryMap { historyProvider, response in
            let contractAddress = request.amountType.token?.contractAddress
            let totalPageCount = try historyProvider.mapper.extractTotalPageCount(
                from: response,
                contractAddress: contractAddress
            )

            return (response, totalPageCount)
        }
        .map { response, totalPageCount in
            // In some rare cases for some really old addresses (like Binance cold wallet `TMuA6YqfCeX8EhbfYEg5y7S4DqzSJireY9` for example),
            // the returned number of total pages count (`BlockBookAddressResponse.totalPages` property) is greater than
            // the actual number of pages.
            // In such cases we have to manually fix the last received chunk of tx history (actually, a duplicated chunk)
            // and treat it as an empty page.
            //
            // Again, Tron Blockbook is a really terrible API
            if let receivedPageNumber = response.page, receivedPageNumber < requestedPageNumber {
                let fixedResponse = BlockBookAddressResponse(
                    page: requestedPageNumber,
                    totalPages: response.totalPages,
                    itemsOnPage: response.itemsOnPage,
                    address: response.address,
                    balance: response.balance,
                    unconfirmedBalance: response.unconfirmedBalance,
                    unconfirmedTxs: response.unconfirmedTxs,
                    txs: response.txs,
                    nonTokenTxs: response.nonTokenTxs,
                    transactions: [],
                    tokens: response.tokens
                )

                return (fixedResponse, receivedPageNumber)
            }

            return (response, totalPageCount)
        }
        .withWeakCaptureOf(self)
        .handleEvents(receiveOutput: { historyProvider, input in
            let (response, totalPageCount) = input
            historyProvider.page = TransactionHistoryIndexPage(number: response.page ?? Constants.initialPageNumber)
            historyProvider.totalPageCount = totalPageCount
        })
        .tryMap { historyProvider, input in
            let (response, _) = input
            let records = try historyProvider.mapper.mapToTransactionRecords(
                response,
                walletAddress: request.address,
                amountType: request.amountType
            )
            .filter { record in
                historyProvider.shouldBeIncludedInHistory(
                    amountType: request.amountType,
                    record: record
                )
            }

            return TransactionHistory.Response(records: records)
        }
        .eraseToAnyPublisher()
    }

    func reset() {
        page = nil
        totalPageCount = 0
        mapper.reset()
    }
}

// MARK: - Constants

private extension TronTransactionHistoryProvider {
    enum Constants {
        // - Note: Tx history API has 1-based indexing (not 0-based indexing)
        static var initialPageNumber: Int { 1 }
    }
}
