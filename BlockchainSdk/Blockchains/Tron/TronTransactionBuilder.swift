//
//  TronTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 26.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftProtobuf
import CryptoSwift

class TronTransactionBuilder {
    private let utils = TronUtils()

    func buildForSign(transaction: Transaction, block: TronBlock) throws -> TronPresignedInput {
        let contract = try contract(transaction: transaction)
        let feeLimit = (transaction.amount.type == .coin) ? 0 : Constants.smartContractFeeLimit

        let blockHeaderRawData = block.block_header.raw_data
        let blockHeader = Protocol_BlockHeader.raw.with {
            $0.timestamp = blockHeaderRawData.timestamp
            $0.number = blockHeaderRawData.number
            $0.version = blockHeaderRawData.version
            $0.txTrieRoot = Data(hex: blockHeaderRawData.txTrieRoot)
            $0.parentHash = Data(hex: blockHeaderRawData.parentHash)
            $0.witnessAddress = Data(hex: blockHeaderRawData.witness_address)
        }

        let blockData = try blockHeader.serializedData()
        let blockHash = blockData.getSha256()
        let refBlockHash = blockHash[8 ..< 16]

        let number = blockHeader.number
        let numberData = Data(Data(from: number).reversed())
        let refBlockBytes = numberData[6 ..< 8]

        let tenHours: Int64 = 10 * 60 * 60 * 1000 // same as WalletCore

        let rawData = Protocol_Transaction.raw.with {
            $0.timestamp = blockHeader.timestamp
            $0.expiration = blockHeader.timestamp + tenHours
            $0.refBlockHash = refBlockHash
            $0.refBlockBytes = refBlockBytes
            $0.contract = [
                contract,
            ]
            $0.feeLimit = feeLimit
        }

        let hash = try rawData.serializedData().sha256()
        return TronPresignedInput(rawData: rawData, hash: hash)
    }

    func buildForSend(rawData: Protocol_Transaction.raw, signature: Data) throws -> Data {
        let transaction = Protocol_Transaction.with {
            $0.rawData = rawData
            $0.signature = [signature]
        }

        return try transaction.serializedData()
    }

    func buildContractEnergyUsageData(amount: Amount, destinationAddress: String) throws -> String {
        let addressData = try utils.convertAddressToBytesPadded(destinationAddress)
        let amountData = try utils.convertAmountPadded(amount)

        let data = (addressData + amountData).hexString.lowercased()
        return data
    }

    // MARK: - Transaction data builder

    func buildForApprove(spender: String, amount: Amount) throws -> Data {
        let spenderData = try utils.convertAddressToBytesPadded(spender)
        let amountData = try utils.convertAmountPadded(amount)

        return spenderData + amountData
    }

    func buildForAllowance(owner: String, spender: String) throws -> String {
        let ownerAddress = try TronUtils().convertAddressToBytesPadded(owner)
        let spenderAddress = try TronUtils().convertAddressToBytesPadded(spender)
        return (ownerAddress + spenderAddress).hexString.lowercased()
    }

    // MARK: - Private

    private func contract(transaction: Transaction) throws -> Protocol_Transaction.Contract {
        let amount = transaction.amount
        let sourceAddress = transaction.sourceAddress
        let destinationAddress = transaction.destinationAddress

        switch amount.type {
        case .coin:
            let parameter = try Protocol_TransferContract.with {
                $0.ownerAddress = try utils.convertAddressToBytes(sourceAddress)
                $0.toAddress = try utils.convertAddressToBytes(destinationAddress)
                $0.amount = amount.int64Value
            }

            return try Protocol_Transaction.Contract.with {
                $0.type = .transferContract
                $0.parameter = try Google_Protobuf_Any(message: parameter)
            }
        case .token(let token):
            let contractData = try buildContractData(transaction: transaction)

            let parameter = try Protocol_TriggerSmartContract.with {
                $0.contractAddress = try utils.convertAddressToBytes(token.contractAddress)
                $0.data = contractData
                $0.ownerAddress = try utils.convertAddressToBytes(sourceAddress)
            }

            return try Protocol_Transaction.Contract.with {
                $0.type = .triggerSmartContract
                $0.parameter = try Google_Protobuf_Any(message: parameter)
            }
        default:
            assertionFailure("Not impkemented")
            throw BlockchainSdkError.notImplemented
        }
    }

    private func buildContractData(transaction: Transaction) throws -> Data {
        let params = try getParams(from: transaction)
        let transactionType = params?.transactionType ?? .transfer

        switch transactionType {
        case .transfer:
            return try buildTransferContractData(amount: transaction.amount, destinationAddress: transaction.destinationAddress)
        case .approval(let data):
            return buildApprovalContractData(data: data)
        }
    }

    private func buildTransferContractData(amount: Amount, destinationAddress: String) throws -> Data {
        let amountData = try utils.convertAmountPadded(amount)
        let destinationData = try utils.convertAddressToBytesPadded(destinationAddress)

        let contractData = TronFunction.transfer.prefix + destinationData + amountData
        return contractData
    }

    private func buildApprovalContractData(data: Data) -> Data {
        let contractData = TronFunction.approve.prefix + data
        return contractData
    }

    private func getParams(from transaction: Transaction) throws -> TronTransactionParams? {
        guard let params = transaction.params else {
            return nil
        }

        guard let tronParams = params as? TronTransactionParams else {
            throw WalletError.failedToBuildTx
        }

        return tronParams
    }
}

// MARK: - Constants

private extension TronTransactionBuilder {
    enum Constants {
        static let smartContractFeeLimit: Int64 = 100_000_000
    }
}

// MARK: - Amount+

private extension Amount {
    var int64Value: Int64 {
        let decimalAmount = value * pow(Decimal(10), decimals)
        return (decimalAmount.rounded() as NSDecimalNumber).int64Value
    }
}

// MARK: - TronPresignedInput

struct TronPresignedInput {
    let rawData: Protocol_Transaction.raw
    let hash: Data
}
