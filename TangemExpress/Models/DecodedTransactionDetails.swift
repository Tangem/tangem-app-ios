//
//  DecodedTransactionDetails.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct DecodedTransactionDetails: Decodable {
    let requestId: String
    let txType: ExpressTransactionType
    // account for debiting tokens (same as toAddress)
    // for CEX doesn't matter from wich address send
    let txFrom: String?
    // swap smart-contract address
    // CEX address for sending transaction
    let txTo: String
    // Memo or tag
    let txExtraId: String?
    // transaction data
    let txData: String?
    // amount (same as fromAmount)
    let txValue: String
    // Additional fee for dex/bridge
    let otherNativeFee: String?
    // Estimated gas for txData
    let gas: String?
    // CEX provider transaction id
    let externalTxId: String?
    // url of CEX provider exchange status page
    let externalTxUrl: String?
    // Address where CEX provider should send the swapped amount
    let payoutAddress: String
}
