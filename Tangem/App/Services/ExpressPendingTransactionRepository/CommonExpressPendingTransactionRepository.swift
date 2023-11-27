//
//  CommonExpressPendingTransactionRepository.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

// TODO: https://tangem.atlassian.net/browse/IOS-4942 @Son
class CommonExpressPendingTransactionRepository {}

extension CommonExpressPendingTransactionRepository: ExpressPendingTransactionRepository {
    func lastCurrencyTransaction() -> ExpressCurrency? {
        return nil
    }

    func hasPending(for network: String) -> Bool {
        false
    }

    func didSendSwapTransaction() {
        /*
         Analytics.log(event: .transactionSent, params: [
             .commonSource: Analytics.ParameterValue.transactionSourceSwap.rawValue,
              .token: swappingTxData.sourceCurrency.symbol,
              .blockchain: swappingTxData.sourceBlockchain.name,
              .feeType: getAnalyticsFeeType()?.rawValue ?? .unknown,
         ])
          */
    }

    func didSendApproveTransaction() {
        /*
         let permissionType: Analytics.ParameterValue = {
             switch getApprovePolicy() {
             case .specified: return .oneTransactionApprove
             case .unlimited: return .unlimitedApprove
             }
         }()

         Analytics.log(event: .transactionSent, params: [
             .commonSource: Analytics.ParameterValue.transactionSourceApprove.rawValue,
             .feeType: getAnalyticsFeeType()?.rawValue ?? .unknown,
             .token: swappingTxData.sourceCurrency.symbol,
             .blockchain: swappingTxData.sourceBlockchain.name,
             .permissionType: permissionType.rawValue,
         ])
          */
    }
}
