//
//  TONStakeKitTransactionHelper.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 29.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TonSwift

class TONStakeKitTransactionHelper {
    func prepareForSign(_ stakingTransaction: StakeKitTransaction) throws -> Data {
        print(stakingTransaction)
        guard let data = stakingTransaction.unsignedData.data(using: .utf8) else {
            throw WalletError.failedToBuildTx
        }
        do {
            let decodedTransaction = try JSONDecoder().decode(UnsignedTransaction.self, from: data)
            let decodedMessage: [UInt8] = try decodedTransaction.message.base64Decoded()
            let cells = try Cell.fromBoc(src: Data(decodedMessage))
            
            guard let cell = cells.first else {
                throw WalletError.failedToBuildTx
            }
            
            let slice = try cell.beginParse()
            let message: MessageRelaxed = try slice.loadType()
            print(message)

        } catch {
            print(error)
        }

        return Data()
    }

    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        signatureInfo: SignatureInfo
    ) throws -> Data {
        Data()
    }
}

struct UnsignedTransaction: Decodable {
    let seqno: String
    let message: String
}
