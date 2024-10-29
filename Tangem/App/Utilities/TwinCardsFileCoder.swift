//
//  TwinCardsFileCoder.swift
//  Tangem
//
//  Created by Andrew Son on 19/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol TwinCardFileEncoder {
    func encode(_ file: TwinCardFile) throws -> Data
}

protocol TwinCardFileDecoder {
    func decode(_ file: File) throws -> TwinCardFile
}

struct TwinCardTlvFileDecoder: TwinCardFileDecoder {
    func decode(_ file: File) throws -> TwinCardFile {
        guard let tlv = Tlv.deserialize(file.data) else {
            throw TangemSdkError.deserializeApduFailed
        }

        let decoder = TlvDecoder(tlv: tlv)
        return TwinCardFile(
            publicKey: try decoder.decode(.fileData),
            fileTypeName: try decoder.decode(.fileTypeName)
        )
    }
}

struct TwinCardTlvFileEncoder: TwinCardFileEncoder {
    func encode(_ file: TwinCardFile) throws -> Data {
        let builder = try TlvBuilder()
            .append(.fileData, value: file.publicKey)
            .append(.fileTypeName, value: file.fileTypeName)

        return builder.serialize()
    }
}

struct TwinCardFile: Codable {
    let publicKey: Data
    let fileTypeName: String
}
