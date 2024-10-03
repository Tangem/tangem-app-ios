//
//  SendTransactionMapper.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

struct SendTransactionMapper {
    func mapResult(
        _ result: TransactionSendResult,
        blockchain: Blockchain
    ) -> SendTransactionDispatcherResult {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: blockchain)
        let explorerUrl = provider.url(transaction: result.hash)

        return SendTransactionDispatcherResult(hash: result.hash, url: explorerUrl)
    }

    func mapError(_ error: Error, transaction: SendTransactionType) -> SendTransactionDispatcherResult.Error {
        let sendError = error as? SendTxError ?? SendTxError(error: error)
        let internalError = sendError.error

        if internalError.toTangemSdkError().isUserCancelled {
            return .userCancelled
        }

        return .sendTxError(transaction: transaction, error: sendError)
    }
}
