//
//  CasperTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import TangemSdk

final class CasperTransactionBuilder {
    // MARK: - Private Properties

    private let curve: EllipticCurve
    private let blockchainDecimalValue: Decimal

    // MARK: - Init

    init(curve: EllipticCurve, blockchainDecimalValue: Decimal) {
        self.curve = curve
        self.blockchainDecimalValue = blockchainDecimalValue
    }

    // MARK: - Implementation

    func buildForSign(transaction: Transaction, timestamp: String) throws -> Data {
        let deploy = try build(transaction: transaction, with: timestamp)

        guard let dataHash = deploy.hash.hexadecimal else {
            throw CasperTransactionBuilderError.undefinedDeployHash
        }

        return dataHash
    }

    func buildForSend(transaction: Transaction, timestamp: String, signature: Data) throws -> Data {
        let deploy = try build(transaction: transaction, with: timestamp)

        let dai1 = CSPRDeployApprovalItem()
        dai1.signer = deploy.header.account
        dai1.signature = try signatureByCurveWithPrefix(signature: signature, for: curve).hexString.lowercased()

        deploy.approvals = [dai1]

        return deploy.toJsonData()
    }
}

// MARK: - Private Implentation

private extension CasperTransactionBuilder {
    func build(transaction: Transaction, with timestamp: String) throws -> CSPRDeploy {
        let deploy = CSPRDeploy()

        let deployHeader = buildDeployHeader(from: transaction, timestamp: timestamp)
        let deployPayment = try buildPayment(with: transaction.fee)
        let deploySession = try buildDeployTransfer(from: transaction)

        deploy.header = deployHeader
        deploy.payment = deployPayment
        deploy.session = deploySession

        deployHeader.bodyHash = DeploySerialization.getBodyHash(fromDeploy: deploy)
        deploy.hash = DeploySerialization.getHeaderHash(fromDeployHeader: deployHeader)

        return deploy
    }

    func buildDeployTransfer(from transaction: Transaction) throws -> ExecutableDeployItem {
        let amountStringValue = String((transaction.amount.value * blockchainDecimalValue).uint64Value)

        let clValueSessionAmountParsed: CLValueWrapper = .u512(U512Class.fromStringToU512(from: amountStringValue))
        let clValueSessionAmount = CLValue()
        clValueSessionAmount.bytes = try CLTypeSerializeHelper.CLValueSerialize(input: clValueSessionAmountParsed)
        clValueSessionAmount.parsed = clValueSessionAmountParsed
        clValueSessionAmount.clType = .u512

        let namedArgSessionAmount = NamedArg()
        namedArgSessionAmount.name = "amount"
        namedArgSessionAmount.argsItem = clValueSessionAmount

        let clValueSessionTargetParsed: CLValueWrapper = .publicKey(transaction.destinationAddress.lowercased())
        let clValueSessionTarget = CLValue()
        clValueSessionTarget.bytes = try CLTypeSerializeHelper.CLValueSerialize(input: clValueSessionTargetParsed)
        clValueSessionTarget.parsed = clValueSessionTargetParsed
        clValueSessionTarget.clType = .publicKey

        let namedArgSessionTarget = NamedArg()
        namedArgSessionTarget.name = "target"
        namedArgSessionTarget.argsItem = clValueSessionTarget

        // 3rd namedArg
        let clValueSessionIdParsed: CLValueWrapper

        if let params = transaction.params as? CasperTransactionParams {
            clValueSessionIdParsed = .optionWrapper(.u64(params.memo))
        } else {
            clValueSessionIdParsed = .optionWrapper(.nullCLValue)
        }

        let clValueSessionId = CLValue()
        clValueSessionId.bytes = try CLTypeSerializeHelper.CLValueSerialize(input: clValueSessionIdParsed)
        clValueSessionId.parsed = clValueSessionIdParsed
        clValueSessionId.clType = .option(.u64)

        let namedArgSessionId = NamedArg()
        namedArgSessionId.name = "id"
        namedArgSessionId.argsItem = clValueSessionId

        let runTimeArgsSession = RuntimeArgs()
        runTimeArgsSession.listNamedArg = [namedArgSessionAmount, namedArgSessionTarget, namedArgSessionId]
        let session: ExecutableDeployItem = .transfer(args: runTimeArgsSession)

        return session
    }

    func buildDeployHeader(from transaction: Transaction, timestamp: String) -> CSPRDeployHeader {
        let deployHeader = CSPRDeployHeader()
        deployHeader.account = transaction.sourceAddress.lowercased()
        deployHeader.timestamp = timestamp
        deployHeader.ttl = Constants.defaultTTL
        deployHeader.gasPrice = Constants.defaultGASPrice
        deployHeader.dependencies = []
        deployHeader.chainName = Constants.defaultChainName
        return deployHeader
    }

    func getBodyHash(deploy: CSPRDeploy) -> String {
        DeploySerialization.getBodyHash(fromDeploy: deploy)
    }

    // Deploy payment initialization
    func buildPayment(with fee: Fee) throws -> ExecutableDeployItem {
        let feeStringValue = String((fee.amount.value * blockchainDecimalValue).uint64Value)

        let clValueFeeParsed: CLValueWrapper = .u512(U512Class.fromStringToU512(from: feeStringValue))

        let clValue = CLValue()
        clValue.bytes = try CLTypeSerializeHelper.CLValueSerialize(input: clValueFeeParsed)
        clValue.clType = .u512
        clValue.parsed = clValueFeeParsed

        let namedArg = NamedArg()
        namedArg.name = "amount"
        namedArg.argsItem = clValue
        let runTimeArgs = RuntimeArgs()
        runTimeArgs.listNamedArg = [namedArg]

        return ExecutableDeployItem.moduleBytes(module_bytes: CSPRBytes.fromStrToBytes(from: ""), args: runTimeArgs)
    }

    func signatureByCurveWithPrefix(signature: Data, for elipticCurve: EllipticCurve) throws -> Data {
        switch elipticCurve {
        case .ed25519, .ed25519_slip0010:
            Data(hexString: CasperConstants.prefixED25519) + signature
        case .secp256k1:
            Data(hexString: CasperConstants.prefixSECP256K1) + signature
        default:
            throw CasperTransactionBuilderError.unsupportedCurve
        }
    }
}

// MARK: - Constants

private extension CasperTransactionBuilder {
    enum Constants {
        static let defaultChainName: String = "casper"
        static let defaultTTL = "1800000ms"
        static let defaultGASPrice: UInt64 = 1
    }
}

// MARK: - Errors

private enum CasperTransactionBuilderError: Error {
    case undefinedDeployHash
    case unsupportedCurve
}
