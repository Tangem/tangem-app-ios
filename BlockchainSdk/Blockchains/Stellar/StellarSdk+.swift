//
//  StellarSdk+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine
import SwiftyJSON

extension AccountService {
    func getAccountDetails(accountId: String) -> AnyPublisher<AccountResponse, Error> {
        let future = Future<AccountResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            getAccountDetails(accountId: accountId) { response in
                switch response {
                case .success(let accountResponse):
                    promise(.success(accountResponse))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }

    func checkTargetAccount(address: String, token: Token?) -> AnyPublisher<StellarTargetAccountResponse, Error> {
        getAccountDetails(accountId: address)
            .map { resp -> StellarTargetAccountResponse in
                guard let token = token else {
                    return StellarTargetAccountResponse(accountCreated: true, trustlineCreated: false)
                }

                let balance = resp.balances.filter { $0.assetCode == token.symbol && $0.assetIssuer == token.contractAddress }
                return StellarTargetAccountResponse(accountCreated: true, trustlineCreated: !balance.isEmpty)
            }
            .tryCatch { error -> AnyPublisher<StellarTargetAccountResponse, Error> in
                guard
                    let stellarError = error as? HorizonRequestError,
                    case .notFound = stellarError else {
                    throw error
                }
                return Just(StellarTargetAccountResponse(accountCreated: false, trustlineCreated: false))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

extension FeeStatsService {
    func getFeeStats() -> AnyPublisher<FeeStatsResponse, Error> {
        Future<FeeStatsResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            getFeeStats { response in
                switch response {
                case .success(let details):
                    promise(.success(details))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension LedgersService {
    func getLatestLedger() -> AnyPublisher<LedgerResponse, Error> {
        let future = Future<LedgerResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            getLedgers(cursor: nil, order: Order.descending, limit: 1) { response in
                switch response {
                case .success(let ledgerResponse):
                    if let lastLedger = ledgerResponse.records.first {
                        promise(.success(lastLedger))
                    } else {
                        promise(.failure(StellarError.failedToFindLatestLedger))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
}

extension TransactionsService {
    func postTransaction(transactionEnvelope: String) -> AnyPublisher<SubmitTransactionResponse, Error> {
        let future = Future<SubmitTransactionResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }

            postTransaction(transactionEnvelope: transactionEnvelope, response: { response in
                switch response {
                case .success(let submitResponse):
                    promise(.success(submitResponse))
                case .failure(let error):
                    promise(.failure(error))
                case .destinationRequiresMemo:
                    promise(.failure(StellarError.requiresMemo))
                }
            })
        }

        return AnyPublisher(future)
    }
}

extension OperationsService {
    func getAllOperations(accountId: String, recordsLimit: Int = 200) -> AnyPublisher<[OperationResponse], Error> {
        func processResponse(_ response: PageResponse<OperationResponse>.ResponseEnum, in promise: (Result<PageResponse<OperationResponse>, Error>) -> Void) {
            switch response {
            case .success(let details):
                promise(.success(details))
            case .failure(let error):
                promise(.failure(error))
            }
        }

        func pageRequest(prevPage: PageResponse<OperationResponse>) -> AnyPublisher<PageResponse<OperationResponse>, Error> {
            Future<PageResponse<OperationResponse>, Error> { promise in
                prevPage.getNextPage { response in
                    processResponse(response, in: promise)
                }
            }
            .eraseToAnyPublisher()
        }

        func pageRequest(accountId: String, recordsLimit: Int = 200) -> AnyPublisher<PageResponse<OperationResponse>, Error> {
            Future<PageResponse<OperationResponse>, Error> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                getOperations(forAccount: accountId, limit: recordsLimit) { response in
                    processResponse(response, in: promise)
                }
            }
            .eraseToAnyPublisher()
        }

        let pageResponseSubject = CurrentValueSubject<PageResponse<OperationResponse>?, Error>(nil)

        return pageResponseSubject
            .flatMap { (page: PageResponse<OperationResponse>?) -> AnyPublisher<PageResponse<OperationResponse>, Error> in
                guard let page = page else {
                    return pageRequest(accountId: accountId, recordsLimit: recordsLimit)
                }

                return pageRequest(prevPage: page)
            }
            .handleEvents(receiveOutput: { (resp: PageResponse<OperationResponse>) in
                resp.records.count == recordsLimit ?
                    pageResponseSubject.send(resp) :
                    pageResponseSubject.send(completion: .finished)
            })
            .map { $0.records }
            .reduce([OperationResponse]()) { $0 + $1 }
            .eraseToAnyPublisher()
    }
}

extension HorizonRequestError {
    var message: String {
        switch self {
        case .emptyResponse:
            return StellarError.emptyResponse.localizedDescription
        case .beforeHistory(let message, _):
            return message
        case .badRequest(let message, _):
            return message
        case .errorOnStreamReceive(let message):
            return message
        case .forbidden(let message, _):
            return message
        case .internalServerError(let message, _):
            return message
        case .notAcceptable(let message, _):
            return message
        case .notFound(let message, _):
            return message
        case .notImplemented(let message, _):
            return message
        case .parsingResponseFailed(let message):
            return message
        case .rateLimitExceeded(let message, _):
            return message
        case .requestFailed(let message, _):
            return message
        case .staleHistory(let message, _):
            return message
        case .unauthorized(let message):
            return message
        case .duplicate(let message, _):
            return message
        case .timeout(let message, _):
            return message
        }
    }

    func parseError() -> Error {
        let hotizonMessage = message
        let json = JSON(parseJSON: hotizonMessage)
        let detailMessage = json["detail"].stringValue
        let extras = json["extras"]
        let codes = extras["result_codes"].rawString() ?? ""
        let errorMessage: String = (!detailMessage.isEmpty && !codes.isEmpty) ? "\(detailMessage). Codes: \(codes)" : hotizonMessage
        return errorMessage
    }
}
