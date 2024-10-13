//
//  RadiantTransactionUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

struct RadiantScriptUtils {
    /// Default implementation BitcoinCash signed scripts
    func buildSignedScripts(signatures: [Data], publicKey: Data, isDer: Bool = false) throws -> [Data] {
        var scripts: [Data] = .init()
        scripts.reserveCapacity(signatures.count)
        for signature in signatures {
            var signDer: Data = signature
            
            signDer = try Secp256k1Signature(with: signature).serializeDer()
            
            var script = Data()
            script.append((signDer.count+1).byte)
            script.append(contentsOf: signDer)
            script.append(UInt8(0x41))
            script.append(UInt8(0x21))
            script.append(contentsOf: publicKey)
            scripts.append(script)
        }
        
        return scripts
    }
    
    /// Lock script for output transaction for address
    func buildOutputScript(address: String) -> Data {
        WalletCore.BitcoinScript.lockScriptForAddress(address: address, coin: .bitcoinCash).data
    }
    
    func writePrevoutHash(_ unspents: [RadiantUnspentOutput], into txToSign: inout Data) {
        let prevouts = Data(unspents.map {
            Data($0.hash.reversed()) + $0.outputIndex.bytes4LE
        }.joined())
        
        let hashPrevouts = prevouts.getDoubleSha256()
        txToSign.append(contentsOf: hashPrevouts)
    }
    
    func writeSequenceHash(_ unspents: [RadiantUnspentOutput], into txToSign: inout Data) {
        let sequence = Data(repeating: UInt8(0xFF), count: 4 * unspents.count)
        let hashSequence = sequence.getDoubleSha256()
        txToSign.append(contentsOf: hashSequence)
    }
    
    /// Default BitcoinCash implementation for set hash output values transaction data
    func writeHashOutput(
        amount: Decimal,
        sourceAddress: String,
        targetAddress: String,
        change: Decimal,
        into txToSign: inout Data
    ) throws {
        //hashOutputs (32-byte hash)
        var outputs = Data()
        outputs.append(contentsOf: amount.bytes8LE)
        
        let sendScript = buildOutputScript(address: targetAddress)
        
        outputs.append(sendScript.count.byte)
        outputs.append(contentsOf: sendScript)
        
        //output for change (if any)
        if change > 0 {
            outputs.append(contentsOf: change.bytes8LE)
            
            let changeOutputScriptBytes = buildOutputScript(address: sourceAddress)
            
            outputs.append(changeOutputScriptBytes.count.byte)
            outputs.append(contentsOf: changeOutputScriptBytes)
        }
        
        let hashOutput = outputs.getDoubleSha256()
        
        // Write bytes
        txToSign.append(contentsOf: hashOutput)
    }
    
    /// Specify for radiant blockchain
    /// See comment here for how it works https://github.com/RadiantBlockchain/radiant-node/blob/master/src/primitives/transaction.h#L493
    /// Since your transactions won't contain pushrefs, it will be very simple, like the commit I sent above
    func writeHashOutputHashes(
        amount: Decimal,
        sourceAddress: String,
        targetAddress: String,
        change: Decimal,
        into txToSign: inout Data
    ) throws {
        let zeroRefHash = [Byte](repeating: 0, count: 32)
        
        //hashOutputs (32-byte hash)
        var outputs = Data()
        
        outputs.append(contentsOf: amount.bytes8LE)
        
        let sendScript = buildOutputScript(address: targetAddress)
        
        // Hash of the locking script
        let scriptHash = sendScript.getDoubleSha256()
        outputs.append(contentsOf: scriptHash)
        
        // Total refs
        outputs.append(0.bytes4LE)
        
        // Add zeroRef 32 bytes
        outputs.append(contentsOf: zeroRefHash)
        
        //output for change (if any)
        if change > 0 {
            outputs.append(contentsOf: change.bytes8LE)
            
            let changeOutputScriptBytes = buildOutputScript(address: sourceAddress)
            
            // Hash of the locking script
            let changeScriptHash = changeOutputScriptBytes.getDoubleSha256()
            outputs.append(contentsOf: changeScriptHash)
            
            // Total refs
            outputs.append(0.bytes4LE)
            
            // Add zeroRef 32 bytes
            outputs.append(contentsOf: zeroRefHash)
        }
        
        let hashOutputHash = outputs.getDoubleSha256()
        
        // Write bytes
        txToSign.append(contentsOf: hashOutputHash)
    }
}
