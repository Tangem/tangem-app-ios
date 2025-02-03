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
    private let transactionBuilder: TONTransactionBuilder

    init(transactionBuilder: TONTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }

    func prepareForSign(_ stakingTransaction: StakeKitTransaction, expireAt: UInt32) throws -> TONPreSignData {
        print(stakingTransaction)
        guard let data = stakingTransaction.unsignedData.data(using: .utf8) else {
            throw WalletError.failedToBuildTx
        }

        let compiledTransaction = try JSONDecoder().decode(TONCompiledTransaction.self, from: data)

        return try transactionBuilder.buildCompiledForSign(
            transaction: compiledTransaction,
            expireAt: expireAt
        )
    }

    func prepareForSend(
        stakingTransaction: StakeKitTransaction,
        preSignData: TONPreSignData,
        signatureInfo: SignatureInfo
    ) throws -> String {
        try transactionBuilder.buildForSend(
            serializedInputData: preSignData.serializedTransactionInput,
            signature: signatureInfo.signature
        )
    }
}

struct TONCompiledTransaction {
    let sequenceNumber: Int
    let comment: String
    let amount: Decimal
    let destination: String
    let bounce: Bool
}

extension TONCompiledTransaction: Decodable {
    enum CodingKeys: CodingKey {
        case seqno
        case message
    }

    init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<TONCompiledTransaction.CodingKeys> = try decoder.container(
            keyedBy: CodingKeys.self
        )

        // sequence number
        let seqno = try container.decode(String.self, forKey: TONCompiledTransaction.CodingKeys.seqno)
        guard let sequenceNumber = Int(seqno) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.seqno], debugDescription: "Failed to parse sequence number")
            )
        }
        self.sequenceNumber = sequenceNumber

        // extract Cell
        let message = try container.decode(String.self, forKey: TONCompiledTransaction.CodingKeys.message)
        let decodedMessage: [UInt8] = try message.base64Decoded()
        let cells = try Cell.fromBoc(src: Data(decodedMessage))

        guard let cell = cells.first else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.message], debugDescription: "No cells found")
            )
        }

        // MessageRelaxed from Cell
        let slice = try cell.beginParse()
        let messageRelaxed: MessageRelaxed = try slice.loadType()

        // comment
        comment = try messageRelaxed.extractComment()

        guard case .internalInfo(let info) = messageRelaxed.info else {
            throw DecodingError.typeMismatch(
                CommonMsgInfoRelaxed.self,
                .init(
                    codingPath: [CodingKeys.message],
                    debugDescription: "CommonMsgInfoRelaxed external type is expected, but internal was found"
                )
            )
        }

        // rest of the parameters
        guard let amountDecimal = info.value.coins.rawValue.decimal else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.message], debugDescription: "Failed to parse coins amount")
            )
        }

        amount = amountDecimal
        bounce = info.bounce
        destination = info.dest.toString(bounceable: info.bounce)
    }
}

private extension MessageRelaxed {
    typealias CodingKeys = TONCompiledTransaction.CodingKeys

    func extractComment() throws -> String {
        let data = Data(hex: body.bits.toHex())

        guard let firstNonNullIndex = data.firstIndex(where: { $0 != 0 }) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.message],
                    debugDescription: "Data is empty or contains only null bytes"
                )
            )
        }

        let subData = data.subdata(in: firstNonNullIndex ..< data.endIndex)

        guard let comment = String(data: subData, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.message],
                    debugDescription: "Failed to create string from UTF-8 encoded data"
                )
            )
        }
        return comment
    }
}
