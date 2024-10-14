//
//  FilecoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import TangemSdk
import WalletCore

enum FilecoinTransactionBuilderError: Error {
    case filecoinFeeParametersNotFound
    case failedToConvertAmountToBigUInt
    case failedToGetDataFromJSON
}

final class FilecoinTransactionBuilder {
    private let decompressedPublicKey: Data
    
    init(publicKey: Wallet.PublicKey) throws {
        self.decompressedPublicKey = try Secp256k1Key(with: publicKey.blockchainKey).decompress()
    }
    
    func buildForSign(transaction: Transaction, nonce: UInt64) throws -> Data {
        guard let feeParameters = transaction.fee.parameters as? FilecoinFeeParameters else {
            throw FilecoinTransactionBuilderError.filecoinFeeParametersNotFound
        }
        
        let input = try makeSigningInput(transaction: transaction, nonce: nonce, feeParameters: feeParameters)
        let txInputData = try input.serializedData()
        
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .filecoin, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)
        
        return preSigningOutput.dataHash
    }
    
    func buildForSend(
        transaction: Transaction,
        nonce: UInt64,
        signatureInfo: SignatureInfo
    ) throws -> FilecoinSignedMessage {
        guard let feeParameters = transaction.fee.parameters as? FilecoinFeeParameters else {
            throw FilecoinTransactionBuilderError.filecoinFeeParametersNotFound
        }
        
        let unmarshalledSignature = try SignatureUtils.unmarshalledSignature(
            from: signatureInfo.signature,
            publicKey: decompressedPublicKey,
            hash: signatureInfo.hash
        )
        
        let signatures = DataVector()
        signatures.add(data: unmarshalledSignature)

        let publicKeys = DataVector()
        publicKeys.add(data: decompressedPublicKey)
        
        let input = try makeSigningInput(transaction: transaction, nonce: nonce, feeParameters: feeParameters)
        let txInputData = try input.serializedData()
        
        let compiledWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: .filecoin,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )
        
        let signingOutput = try FilecoinSigningOutput(serializedData: compiledWithSignatures)
                
        guard let jsonData = signingOutput.json.data(using: .utf8) else {
            throw FilecoinTransactionBuilderError.failedToGetDataFromJSON
        }
        
        return try JSONDecoder().decode(FilecoinSignedMessage.self, from: jsonData)
    }
    
    private func makeSigningInput(
        transaction: Transaction,
        nonce: UInt64,
        feeParameters: FilecoinFeeParameters
    ) throws -> FilecoinSigningInput {
        guard let value = transaction.amount.bigUIntValue else {
            throw FilecoinTransactionBuilderError.failedToConvertAmountToBigUInt
        }
        
        return FilecoinSigningInput.with { input in
            input.to = transaction.destinationAddress
            input.nonce = nonce
            
            input.value = value.serialize()
            
            input.gasLimit = feeParameters.gasLimit
            input.gasFeeCap = feeParameters.gasFeeCap.serialize()
            input.gasPremium = feeParameters.gasPremium.serialize()
            
            input.publicKey = decompressedPublicKey
        }
    }
}
