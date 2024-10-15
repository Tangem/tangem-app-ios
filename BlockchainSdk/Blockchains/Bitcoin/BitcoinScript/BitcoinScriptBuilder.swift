//
//  BitcoinScriptBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 28.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class BitcoinScriptBuilder {
    private var data = Data()
    private let scriptChunkHelper = ScriptChunkHelper()

    func makeMultisig(publicKeys: [Data], signaturesRequired: Int) throws -> BitcoinScript {
        let publicKeys = publicKeys.sorted(by: { $0.lexicographicallyPrecedes($1) })

        // First make sure the arguments make sense.
        // We need at least one signature
        guard signaturesRequired > 0 else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        // And we cannot have more signatures than available pubkeys.
        guard publicKeys.count >= signaturesRequired else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        // Both M and N should map to OP_<1..16>
        let mOpcode: OpCode = OpCodeFactory.opcode(for: signaturesRequired)
        let nOpcode: OpCode = OpCodeFactory.opcode(for: publicKeys.count)

        guard mOpcode != .OP_INVALIDOPCODE else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        guard nOpcode != .OP_INVALIDOPCODE else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        try append(mOpcode)
        for pubkey in publicKeys {
            try appendData(pubkey)
        }
        try append(nOpcode)
        try append(.OP_CHECKMULTISIG)

        let chunks = try parseData(data)

        return BitcoinScript(chunks: chunks, data: data)
    }

    private func append(_ opcode: OpCode) throws {
        guard !BitcoinScriptBuilder.invalidOpCodes.contains(where: { $0 == opcode }) else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        data += Data(opcode.value)
    }

    private func appendData(_ newData: Data) throws  {
        guard !newData.isEmpty else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        guard let addedScriptData = scriptChunkHelper.scriptData(for: newData, preferredLengthEncoding: -1) else {
            throw BlockchainSdkError.failedToCreateMultisigScript
        }

        data += addedScriptData
    }

    private func parseData(_ data: Data) throws -> [BitcoinScriptChunk] {
        guard !data.isEmpty else {
            return [BitcoinScriptChunk]()
        }

        var chunks = [BitcoinScriptChunk]()

        var i: Int = 0
        let count: Int = data.count

        while i < count {
            // Exit if failed to parse
            let chunk = try scriptChunkHelper.parseChunk(from: data, offset: i)
            chunks.append(chunk)
            i += chunk.range.count
        }
        return chunks
    }
}

private extension BitcoinScriptBuilder {
    static let invalidOpCodes: [OpCode] = [
        .OP_PUSHDATA1,
        .OP_PUSHDATA2,
        .OP_PUSHDATA4,
        .OP_INVALIDOPCODE
    ]
}
